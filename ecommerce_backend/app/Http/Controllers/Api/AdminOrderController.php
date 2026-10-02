<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use App\Services\FirebaseService;

class AdminOrderController extends Controller
{
    /**
     * Get all customer orders for Admin Order Management.
     */
    public function index()
    {
        $orders = Order::with(['items', 'latestPayment'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($orders);
    }

    /**
     * Update order status (e.g. preparing, dispatched, delivered, cancelled)
     * and synchronize updated status to Firebase Cloud Firestore.
     */
    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|string',
        ]);

        $order = Order::with(['items', 'latestPayment'])->findOrFail($id);
        $order->status = strtolower($request->status);
        $order->save();

        // Real-time synchronization to Firebase Cloud Firestore
        FirebaseService::syncOrder($order);

        return response()->json([
            'success' => true,
            'message' => 'Order status updated successfully',
            'order' => $order,
        ]);
    }
}
