<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderChat;
use Illuminate\Http\Request;

class OrderChatController extends Controller
{
    /**
     * Get all chat messages for a specific order.
     */
    public function index($orderId)
    {
        $order = Order::where('order_number', $orderId)
            ->orWhere('id', $orderId)
            ->first();

        $orderKey = $order ? $order->order_number : $orderId;

        $messages = OrderChat::where('order_id', $orderKey)
            ->orWhere('order_id', (string) $orderId)
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
            'sender_role' => 'required|string|in:customer,admin,Customer,Admin',
            'sender_name' => 'required|string|max:100',
            'message' => 'required|string|max:2000',
        ]);

        $order = Order::where('order_number', $orderId)
            ->orWhere('id', $orderId)
            ->first();

        $orderKey = $order ? $order->order_number : $orderId;

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
