<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderReview;
use Illuminate\Http\Request;

class OrderReviewController extends Controller
{
    /**
     * Submit rating and feedback for a delivered order.
     */
    public function store(Request $request, $orderId)
    {
        $validated = $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'feedback' => 'nullable|string|max:1000',
            'user_id' => 'nullable|integer',
        ]);

        $order = Order::where('order_number', $orderId)
            ->orWhere('id', $orderId)
            ->firstOrFail();

        $orderKey = $order->order_number;
        $userId = $validated['user_id'] ?? auth('sanctum')->id() ?? $order->user_id ?? 1;

        $review = OrderReview::updateOrCreate(
            ['order_id' => $orderKey],
            [
                'user_id' => $userId,
                'rating' => $validated['rating'],
                'feedback' => $validated['feedback'] ?? null,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Thank you for your rating and feedback!',
            'review' => $review,
        ], 201);
    }

    /**
     * Get review for an order.
     */
    public function show($orderId)
    {
        $order = Order::where('order_number', $orderId)
            ->orWhere('id', $orderId)
            ->first();

        $orderKey = $order ? $order->order_number : $orderId;

        $review = OrderReview::where('order_id', $orderKey)
            ->orWhere('order_id', (string) $orderId)
            ->first();

        return response()->json([
            'success' => true,
            'review' => $review,
        ]);
    }
}
