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
        $orders = OrderService::listOrders(null, null, null, $status, true);

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
        $action = strtoupper($request->input('action', 'APPROVE'));

        if ($action === 'REJECT') {
            $reason = $request->input('notes') 
                ?? $request->input('rejection_reason') 
                ?? 'Receipt proof was rejected by admin.';

            $order = OrderService::updateOrderStatus((string) $orderId, 'PAYMENT_REJECTED', [
                'payment_status' => 'rejected',
                'rejection_reason' => $reason,
                'admin_notes' => $reason,
            ]);

            if (!$order) {
                return response()->json(['message' => 'Order not found'], 404);
            }

            return response()->json([
                'success' => true,
                'message' => "Order #{$order['order_number']} receipt was rejected. Customer can re-upload valid proof.",
                'order' => $order,
            ]);
        }

        // Action is APPROVE
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

    /**
    /**
     * POST /api/admin/orders/{id}/reject-receipt
     */
    public function rejectReceipt(Request $request, $id): JsonResponse
    {
        return $this->verifyOrder($request->merge(['action' => 'REJECT']), $id);
    }

    /**
     * GET /api/admin/analytics
     */
    public function analytics(Request $request): JsonResponse
    {
        $range = strtolower($request->query('range', '7days'));

        // Base query for valid orders
        $validOrdersQuery = \App\Models\Order::whereNotIn('status', ['CANCELLED', 'REJECTED']);

        $totalRevenue = (float) (clone $validOrdersQuery)->sum('total_amount');
        $totalOrders = (int) (clone $validOrdersQuery)->count();
        
        $activeUsers = (int) \App\Models\User::where(function ($q) {
            $q->where('role', 'customer')
              ->orWhereNull('role');
        })->count();

        $labels = [];
        $values = [];

        $now = now();

        if ($range === '7days' || $range === 'last 7 days') {
            for ($i = 6; $i >= 0; $i--) {
                $date = $now->copy()->subDays($i);
                $dayLabel = $date->format('D');
                $dayStart = $date->copy()->startOfDay();
                $dayEnd = $date->copy()->endOfDay();

                $rev = (float) \App\Models\Order::whereNotIn('status', ['CANCELLED', 'REJECTED'])
                    ->whereBetween('created_at', [$dayStart, $dayEnd])
                    ->sum('total_amount');

                $labels[] = $dayLabel;
                $values[] = round($rev, 2);
            }
        } elseif ($range === '30days' || $range === 'last 30 days') {
            for ($i = 29; $i >= 0; $i -= 3) {
                $date = $now->copy()->subDays($i);
                $dayLabel = $date->format('M d');
                $dayStart = $date->copy()->subDays(2)->startOfDay();
                $dayEnd = $date->copy()->endOfDay();

                $rev = (float) \App\Models\Order::whereNotIn('status', ['CANCELLED', 'REJECTED'])
                    ->whereBetween('created_at', [$dayStart, $dayEnd])
                    ->sum('total_amount');

                $labels[] = $dayLabel;
                $values[] = round($rev, 2);
            }
        } elseif ($range === '90days' || $range === 'last 90 days') {
            for ($i = 11; $i >= 0; $i--) {
                $date = $now->copy()->subWeeks($i);
                $weekLabel = 'W' . $date->format('W');
                $weekStart = $date->copy()->startOfWeek();
                $weekEnd = $date->copy()->endOfWeek();

                $rev = (float) \App\Models\Order::whereNotIn('status', ['CANCELLED', 'REJECTED'])
                    ->whereBetween('created_at', [$weekStart, $weekEnd])
                    ->sum('total_amount');

                $labels[] = $weekLabel;
                $values[] = round($rev, 2);
            }
        } else {
            for ($i = 11; $i >= 0; $i--) {
                $date = $now->copy()->subMonths($i);
                $monthLabel = $date->format('M');
                $monthStart = $date->copy()->startOfMonth();
                $monthEnd = $date->copy()->endOfMonth();

                $rev = (float) \App\Models\Order::whereNotIn('status', ['CANCELLED', 'REJECTED'])
                    ->whereBetween('created_at', [$monthStart, $monthEnd])
                    ->sum('total_amount');

                $labels[] = $monthLabel;
                $values[] = round($rev, 2);
            }
        }

        $recentOrders = \App\Models\Order::orderBy('created_at', 'desc')
            ->take(5)
            ->get()
            ->map(function ($order) {
                return [
                    'order_number' => $order->order_number,
                    'customer_name' => $order->customer_name ?? 'Guest',
                    'total_amount' => (float) $order->total_amount,
                    'status' => $order->status,
                    'created_at' => $order->created_at ? $order->created_at->format('M d, Y h:i A') : '',
                ];
            });

        return response()->json([
            'success' => true,
            'total_revenue' => round($totalRevenue, 2),
            'total_orders' => $totalOrders,
            'active_users' => $activeUsers,
            'range' => $range,
            'trend' => [
                'labels' => $labels,
                'values' => $values,
            ],
            'recent_orders' => $recentOrders,
        ], Response::HTTP_OK);
    }
}
