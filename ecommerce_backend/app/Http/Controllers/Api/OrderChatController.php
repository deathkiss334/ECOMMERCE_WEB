<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OrderChat;
use App\Services\OrderService;
use Illuminate\Http\Request;

class OrderChatController extends Controller
{
    /**
     * Get all chat messages for a specific order.
     */
    public function index($orderId)
    {
        $cleanId = trim((string) $orderId);
        $order = OrderService::findOrder($cleanId);
        $orderKey = $order ? $order['order_number'] : $cleanId;

        if (empty($orderKey)) {
            return response()->json([
                'success' => true,
                'order_id' => '',
                'messages' => [],
            ]);
        }

        // Strictly lock messages to this exact specific order_number only
        $messages = OrderChat::where('order_id', $orderKey)
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'order_id' => $orderKey,
            'messages' => $messages,
        ]);
    }

    /**
     * Send a new chat message for an order.
     */
    public function store(Request $request, $orderId)
    {
        $validated = $request->validate([
            'sender_role' => 'required|string',
            'sender_name' => 'required|string|max:100',
            'message' => 'required|string|max:2000',
        ]);

        $cleanId = trim((string) $orderId);
        $order = OrderService::findOrder($cleanId);
        $orderKey = $order ? $order['order_number'] : $cleanId;

        if (empty($orderKey)) {
            return response()->json(['message' => 'Invalid order identifier for chat'], 400);
        }

        $chat = OrderChat::create([
            'order_id' => $orderKey,
            'sender_role' => strtolower($validated['sender_role']),
            'sender_name' => $validated['sender_name'],
            'message' => $validated['message'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Chat message sent successfully',
            'chat' => $chat,
        ], 201);
    }
}
