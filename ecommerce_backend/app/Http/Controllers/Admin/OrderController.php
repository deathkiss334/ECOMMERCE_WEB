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
        $orders = Order::with('items')->orderBy('created_at', 'desc')->get();
        return view('admin.orders.index', compact('orders'));
    }

    public function updateStatus(Request $request, $id)
    {
        $order = Order::findOrFail($id);
        $request->validate(['status' => 'required|string']);
        
        $order->update(['status' => $request->status]);

        // Synchronize updated order status to Firebase in real-time
        FirebaseService::syncOrder($order);
        
        return redirect()->back()->with('success', 'Order status updated successfully!');
    }
}
