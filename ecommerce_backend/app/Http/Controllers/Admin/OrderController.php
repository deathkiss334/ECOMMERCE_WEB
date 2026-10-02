<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use App\Services\FirebaseService;

class OrderController extends Controller
{
    public function index()
    {
        $orders = Order::with(['items', 'latestPayment'])->orderBy('created_at', 'desc')->get();
        return view('admin.orders.index', compact('orders'));
    }

    public function updateStatus(Request $request, $id)
    {
        $order = Order::with('latestPayment')->findOrFail($id);
        $request->validate(['status' => 'required|string']);
        
        $order->status = $request->status;

        // If advancing to preparing, mark payment as paid
        if ($request->status === 'preparing' || $request->status === 'dispatched' || $request->status === 'completed') {
            if ($order->latestPayment) {
                $order->latestPayment->update(['status' => 'succeeded']);
            }
            $order->payment_status = 'paid';
        }

        $order->save();

        // Synchronize updated order status to Firebase in real-time
        FirebaseService::syncOrder($order);
        
        return redirect()->back()->with('success', 'Order #' . $order->order_number . ' status updated to ' . strtoupper($order->status) . '!');
    }

    public function verifyPayment($id)
    {
        $order = Order::with('latestPayment')->findOrFail($id);

        if ($order->latestPayment) {
            $order->latestPayment->update(['status' => 'succeeded']);
        }

        $order->update([
            'payment_status' => 'paid',
            'status' => 'preparing',
        ]);

        FirebaseService::syncOrder($order);

        return redirect()->back()->with('success', 'Order #' . $order->order_number . ' GCash payment verified! Order is now PREPARING in the kitchen.');
    }
}
