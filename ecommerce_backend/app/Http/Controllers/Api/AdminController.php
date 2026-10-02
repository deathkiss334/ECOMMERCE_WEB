<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\OrderService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AdminController extends Controller
{
    /**
     * GET /api/admin/orders
     */
    public function orders(Request $request): JsonResponse
    {
        $status = $request->query('status');
        $orders = OrderService::listOrders(null, null, null, $status);

        return response()->json($orders, Response::HTTP_OK);
    }

    /**
     * POST /api/admin/orders/{id}/status
     * PATCH /api/admin/orders/{id}/status
     */
    public function updateOrderStatus(Request $request, $id): JsonResponse
    {
        $request->validate([
            'status' => 'required|string',
        ]);

        $extra = [];
        if ($request->filled('lalamove_tracking_url')) {
            $extra['lalamove_tracking_url'] = $request->input('lalamove_tracking_url');
        } elseif ($request->filled('tracking_url')) {
            $extra['lalamove_tracking_url'] = $request->input('tracking_url');
        }

        if ($request->filled('rejection_reason')) {
            $extra['rejection_reason'] = $request->input('rejection_reason');
        }

        $order = OrderService::updateOrderStatus((string) $id, $request->input('status'), $extra);

        if (!$order) {
            return response()->json(['message' => 'Order not found'], 404);
        }

        return response()->json([
            'success' => true,
            'message' => "Order #{$order['order_number']} status updated to {$order['status']}.",
            'order' => $order,
        ], Response::HTTP_OK);
    }

    /**
     * PATCH /api/orders/{orderId}/tracking
     * PATCH /api/admin/orders/{orderId}/tracking
     */
    public function updateTrackingUrl(Request $request, $id): JsonResponse
    {
        $request->validate([
            'tracking_url' => 'nullable|string',
            'lalamove_tracking_url' => 'nullable|string',
        ]);

        $trackingUrl = $request->input('lalamove_tracking_url') ?? $request->input('tracking_url');

        $order = OrderService::findOrder((string) $id);
        if (!$order) {
            return response()->json(['message' => 'Order not found'], 404);
        }

        $updated = OrderService::updateOrderStatus((string) $id, $order['status'], [
            'lalamove_tracking_url' => $trackingUrl,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Lalamove tracking link updated successfully.',
            'order' => $updated,
            'tracking_url' => $trackingUrl,
            'lalamove_tracking_url' => $trackingUrl,
        ]);
    }

    /**
     * PATCH /api/admin/orders/{orderId}/verify
     */
    public function verifyOrder(Request $request, $orderId): JsonResponse
    {
        $order = OrderService::updateOrderStatus((string) $orderId, 'PREPARING', [
            'payment_status' => 'paid',
            'verified_at' => now(),
            'admin_notes' => 'Payment verified by Admin.',
        ]);

        if (!$order) {
            return response()->json(['message' => 'Order not found'], 404);
        }

        return response()->json([
            'success' => true,
            'message' => "Order #{$order['order_number']} payment verified successfully! Kitchen is preparing the order.",
            'order' => $order,
        ]);
    }

    /**
     * POST /api/admin/orders/{id}/verify-payment
     */
    public function verifyPayment(Request $request, $id): JsonResponse
    {
        return $this->verifyOrder($request, $id);
    }
}
