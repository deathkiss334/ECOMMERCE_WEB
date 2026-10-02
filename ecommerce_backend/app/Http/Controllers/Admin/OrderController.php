<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;

class OrderController extends Controller
{
    public function index()
    {
        $orders = Order::with(['items', 'latestPayment', 'chats'])->orderBy('created_at', 'desc')->get();
        return view('admin.orders.index', compact('orders'));
    }

    public function updateStatus(Request $request, $id)
    {
        $order = Order::with('latestPayment')->where('id', $id)->orWhere('order_number', $id)->firstOrFail();
        $request->validate(['status' => 'required|string']);
        
        $newStatus = strtoupper($request->status);
        $order->status = $newStatus;

        // If tracking URL passed during status update
        if ($request->filled('lalamove_tracking_url')) {
            $order->lalamove_tracking_url = $request->lalamove_tracking_url;
        }

        // Status-based state adjustments
        if (in_array($newStatus, ['PREPARING', 'DISPATCHED', 'OUT_FOR_DELIVERY', 'RIDER_ARRIVED', 'DELIVERED', 'COMPLETED'])) {
            if ($order->latestPayment && $order->latestPayment->status !== 'succeeded') {
                $order->latestPayment->update(['status' => 'succeeded']);
            }
            $order->payment_status = 'paid';
            if (!$order->verified_at) {
                $order->verified_at = now();
            }
        }

        $order->save();
        
        if ($request->wantsJson()) {
            return response()->json(['success' => true, 'order' => $order]);
        }

        return redirect()->back()->with('success', 'Order #' . $order->order_number . ' updated to ' . $newStatus . '!');
    }

    public function verifyPayment(Request $request, $id)
    {
        $order = Order::with('latestPayment')->where('id', $id)->orWhere('order_number', $id)->firstOrFail();

        if ($order->latestPayment) {
            $order->latestPayment->update(['status' => 'succeeded']);
        }

        $order->update([
            'payment_status' => 'paid',
            'status' => 'PREPARING',
            'verified_at' => now(),
        ]);

        if ($request->wantsJson()) {
            return response()->json(['success' => true, 'order' => $order]);
        }

        return redirect()->back()->with('success', 'Order #' . $order->order_number . ' payment verified! Kitchen is now PREPARING the food.');
    }

    public function rejectReceipt(Request $request, $id)
    {
        $order = Order::with('latestPayment')->where('id', $id)->orWhere('order_number', $id)->firstOrFail();
        
        $reason = $request->input('rejection_reason', 'Receipt image is invalid or payment was not received.');
        
        if ($order->latestPayment) {
            $order->latestPayment->update(['status' => 'failed']);
        }

        $order->update([
            'payment_status' => 'rejected',
            'status' => 'PAYMENT_PENDING',
            'rejection_reason' => $reason,
        ]);

        if ($request->wantsJson()) {
            return response()->json(['success' => true, 'order' => $order]);
        }

        return redirect()->back()->with('success', 'Receipt for Order #' . $order->order_number . ' was rejected.');
    }

    public function updateTrackingUrl(Request $request, $id)
    {
        $order = Order::where('id', $id)->orWhere('order_number', $id)->firstOrFail();
        $request->validate(['lalamove_tracking_url' => 'required|url']);

        $order->update([
            'lalamove_tracking_url' => $request->lalamove_tracking_url
        ]);

        if ($request->wantsJson()) {
            return response()->json(['success' => true, 'lalamove_tracking_url' => $order->lalamove_tracking_url]);
        }

        return redirect()->back()->with('success', 'Lalamove Tracking URL saved for Order #' . $order->order_number . '!');
    }
}

