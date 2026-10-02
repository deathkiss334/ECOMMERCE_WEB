<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AdminController extends Controller
{
    /**
     * GET /api/admin/orders
     * List all orders for administrative dashboard, with optional status filter.
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function orders(Request $request): JsonResponse
    {
        $query = Order::with(['items', 'latestPayment']);

        if ($request->has('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        $orders = $query->orderBy('created_at', 'desc')->get();

        return response()->json($orders, Response::HTTP_OK);
    }

    /**
     * POST /api/admin/orders/{id}/status
     * Update order fulfillment status.
     *
     * @param Request $request
     * @param int $id
     * @return JsonResponse
     */
    public function updateOrderStatus(Request $request, $id): JsonResponse
    {
        $request->validate([
            'status' => 'required|string',
        ]);

        $order = Order::with('latestPayment')
            ->where('order_number', $id)
            ->orWhere('id', $id)
            ->firstOrFail();

        $order->status = strtoupper($request->status);
        if ($order->status === 'DELIVERED') {
            $order->payment_status = 'paid';
        }

        if ($request->filled('lalamove_tracking_url')) {
            $order->lalamove_tracking_url = $request->input('lalamove_tracking_url');
        } elseif ($request->filled('tracking_url')) {
            $order->lalamove_tracking_url = $request->input('tracking_url');
        }

        $order->save();

        \App\Services\FirebaseService::syncOrder($order);

        return response()->json([
            'success' => true,
            'message' => "Order #{$order->order_number} status updated to {$order->status}.",
            'order' => $order,
        ], Response::HTTP_OK);
    }

    /**
     * PATCH /api/orders/{orderId}/tracking
     * PATCH /api/admin/orders/{orderId}/tracking
     * Update Lalamove tracking link.
     */
    public function updateTrackingUrl(Request $request, $id): JsonResponse
    {
        $request->validate([
            'tracking_url' => 'nullable|string',
            'lalamove_tracking_url' => 'nullable|string',
        ]);

        $order = Order::where('order_number', $id)
            ->orWhere('id', $id)
            ->firstOrFail();

        $trackingUrl = $request->input('lalamove_tracking_url') ?? $request->input('tracking_url');
        $order->lalamove_tracking_url = $trackingUrl;
        $order->save();

        \App\Services\FirebaseService::syncOrder($order);

        return response()->json([
            'success' => true,
            'message' => "Lalamove tracking link updated for Order #{$order->order_number}.",
            'lalamove_tracking_url' => $trackingUrl,
            'order' => $order,
        ], Response::HTTP_OK);
    }

    /**
     * PATCH /api/admin/orders/{orderId}/verify
     * Body: { action: 'APPROVE' | 'REJECT', notes?: string }
     */
    public function verifyOrder(Request $request, $orderId): JsonResponse
    {
        $validated = $request->validate([
            'action' => 'required|string|in:APPROVE,REJECT,approve,reject',
            'notes' => 'nullable|string',
        ]);

        $order = Order::with('latestPayment')
            ->where('order_number', $orderId)
            ->orWhere('id', $orderId)
            ->firstOrFail();

        $action = strtoupper($validated['action']);
        $notes = $validated['notes'] ?? ($action === 'APPROVE' ? 'GCash payment confirmed by store admin.' : 'Payment receipt rejected. Please re-check GCash reference or transfer proof.');

        if ($action === 'APPROVE') {
            if ($order->latestPayment) {
                $order->latestPayment->update(['status' => 'succeeded']);
            }
            $order->update([
                'status' => 'PREPARING',
                'payment_status' => 'paid',
                'verified_at' => now(),
                'admin_notes' => $notes,
            ]);
            $msg = "Order #{$order->order_number} verified and accepted! Kitchen notified to start preparing.";
        } else {
            if ($order->latestPayment) {
                $order->latestPayment->update(['status' => 'failed']);
            }
            $order->update([
                'status' => 'PAYMENT_REJECTED',
                'payment_status' => 'rejected',
                'rejection_reason' => $notes,
                'admin_notes' => $notes,
            ]);
            $msg = "Order #{$order->order_number} rejected. Customer requested to re-upload proof.";
        }

        \App\Services\FirebaseService::syncOrder($order);

        return response()->json([
            'success' => true,
            'message' => $msg,
            'order' => $order,
        ], Response::HTTP_OK);
    }

    /**
     * POST /api/admin/orders/{id}/verify-payment
     * Backward-compatible alias for verifyPayment.
     */
    public function verifyPayment(int $id): JsonResponse
    {
        $request = request();
        return $this->verifyOrder($request, (string) $id);
    }

    /**
     * GET /api/admin/users
     * List all registered users in the SQLite database.
     *
     * @return JsonResponse
     */
    public function users(): JsonResponse
    {
        $users = User::select('id', 'name', 'email', 'phone', 'role', 'auth_provider', 'created_at', 'updated_at')
            ->orderBy('id', 'asc')
            ->get();

        return response()->json($users, Response::HTTP_OK);
    }

    /**
     * PUT /api/admin/users/{id}/role
     * Update a user's role (promote/demote admin or customer).
     *
     * @param Request $request
     * @param int $id
     * @return JsonResponse
     */
    public function updateUserRole(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'role' => 'required|string|in:customer,admin',
        ]);

        $user = User::findOrFail($id);
        $user->role = $request->role;
        $user->save();

        return response()->json([
            'message' => "User {$user->email} role updated to {$user->role}.",
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
            ],
        ], Response::HTTP_OK);
    }
}
