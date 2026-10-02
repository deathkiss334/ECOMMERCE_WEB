<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OrderReview;
use App\Services\OrderService;
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
            'comment' => 'nullable|string|max:1000',
            'user_id' => 'nullable',
        ]);

        $order = OrderService::findOrder((string) $orderId);
        $orderKey = $order ? $order['order_number'] : $orderId;
        $rawUserId = $order['user_id'] ?? auth('sanctum')->id() ?? null;
        $userId = ($rawUserId && is_numeric($rawUserId)) ? (int) $rawUserId : null;
        $feedback = $validated['feedback'] ?? $validated['comment'] ?? 'Great food and fast delivery!';

        $review = OrderReview::updateOrCreate(
            ['order_id' => $orderKey],
            [
                'user_id' => $userId,
                'rating' => (int) $validated['rating'],
                'feedback' => $feedback,
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
        $order = OrderService::findOrder((string) $orderId);
        $orderKey = $order ? $order['order_number'] : $orderId;

        $review = OrderReview::where('order_id', $orderKey)->first();

        return response()->json([
            'success' => true,
            'review' => $review,
        ]);
    }
}
