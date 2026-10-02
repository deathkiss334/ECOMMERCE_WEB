<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Services\OrderService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderHistoryController extends Controller
{
    /**
     * GET /api/orders
     * Return orders list for tracking / history.
     */
    public function index(Request $request)
    {
        $orderNumbers = $request->query('order_numbers');
        $email = $request->query('email');
        $phone = $request->query('phone');
        $status = $request->query('status');

        $numbersList = null;
        if ($orderNumbers && trim($orderNumbers) !== '') {
            $numbersList = array_values(array_filter(array_map('trim', explode(',', $orderNumbers))));
        }

        $orders = OrderService::listOrders($email, $numbersList, $phone, $status);

        return response()->json($orders);
    }

    /**
     * GET /api/orders/:orderId/status
     */
    public function orderStatus(string $orderId)
    {
        $order = OrderService::findOrder($orderId);

        if (!$order) {
            abort(404, 'Order not found');
        }

        return response()->json([
            'orderId' => $order['order_number'],
            'order_number' => $order['order_number'],
            'order_id' => $order['order_id'],
            'id' => $order['id'] ?? 1,
            'userId' => $order['user_id'] ?? null,
            'totalAmount' => (float) $order['total_amount'],
            'total_amount' => (float) $order['total_amount'],
            'status' => strtoupper($order['status']),
            'payment_status' => $order['payment_status'] ?? 'unpaid',
            'gcashRefNumber' => $order['gcash_ref_number'] ?? null,
            'gcash_ref_number' => $order['gcash_ref_number'] ?? null,
            'receiptImageUrl' => $order['receipt_image_url'] ?? null,
            'receipt_image_url' => $order['receipt_image_url'] ?? null,
            'adminNotes' => $order['admin_notes'] ?? null,
            'admin_notes' => $order['admin_notes'] ?? null,
            'rejectionReason' => $order['rejection_reason'] ?? null,
            'rejection_reason' => $order['rejection_reason'] ?? null,
            'lalamove_tracking_url' => $order['lalamove_tracking_url'] ?? null,
            'createdAt' => $order['created_at'] ?? now()->toIso8601String(),
            'created_at' => $order['created_at'] ?? now()->toIso8601String(),
            'verifiedAt' => $order['verified_at'] ?? null,
            'verified_at' => $order['verified_at'] ?? null,
            'items' => $order['items'] ?? [],
        ]);
    }

    /**
     * POST /api/orders/reviews
     * Store review in review_tbl.
     */
    public function storeReview(Request $request)
    {
        $validated = $request->validate([
            'order_id' => 'required',
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string',
            'review_desc' => 'nullable|string',
            'product_id' => 'nullable',
        ]);

        $orderId = (string) $validated['order_id'];
        $order = OrderService::findOrder($orderId);
        $orderKey = $order ? $order['order_number'] : $orderId;

        $rawUserId = $order['user_id'] ?? auth('sanctum')->id() ?? null;
        $userId = ($rawUserId && is_numeric($rawUserId)) ? (int) $rawUserId : null;
        $feedback = $validated['comment'] ?? $validated['review_desc'] ?? 'Delicious food and great service!';

        $review = \App\Models\OrderReview::updateOrCreate(
            ['order_id' => $orderKey],
            [
                'user_id' => $userId,
                'rating' => (int) $validated['rating'],
                'feedback' => $feedback,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Review successfully submitted!',
            'review' => $review,
        ]);
    }
}
