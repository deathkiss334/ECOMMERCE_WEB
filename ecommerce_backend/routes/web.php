<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\OrderController;
use App\Models\Order;
use App\Models\Payment;
use App\Models\PaymentTransaction;
use Illuminate\Http\Request;

use App\Http\Controllers\DbViewerController;

// ── Root Endpoint: Clean API Status Dashboard (Clarifies Backend vs Frontend) ──
Route::get('/', function () {
    return view('welcome_api');
});

// ── SQLite Database Browser Viewer ──
Route::get('/db-viewer', [DbViewerController::class, 'index']);

// Phase 4: Admin Dashboard Routes
Route::redirect('/admin', '/admin/orders');
Route::get('/admin/orders', [OrderController::class, 'index'])->name('admin.orders.index');
Route::post('/admin/orders/{id}/status', [OrderController::class, 'updateStatus'])->name('admin.orders.update-status');
Route::post('/admin/orders/{id}/verify-payment', [OrderController::class, 'verifyPayment'])->name('admin.orders.verify-payment');
Route::post('/admin/orders/{id}/reject-receipt', [OrderController::class, 'rejectReceipt'])->name('admin.orders.reject-receipt');
Route::post('/admin/orders/{id}/tracking', [OrderController::class, 'updateTrackingUrl'])->name('admin.orders.tracking');

// Sandbox Payment Proof-of-Concept Portal (Interactive GCash / Maya Simulation)
Route::get('/sandbox/checkout/{order_number}', function ($order_number) {
    $order = Order::with(['items', 'latestPayment'])->where('order_number', $order_number)->firstOrFail();
    return view('sandbox.checkout', compact('order'));
});

Route::post('/sandbox/checkout/{order_number}/pay', function (Request $request, $order_number) {
    $order = Order::with('latestPayment')->where('order_number', $order_number)->firstOrFail();
    
    // 1. Mark payment as succeeded
    if ($order->latestPayment) {
        $order->latestPayment->update(['status' => 'succeeded']);
        
        PaymentTransaction::create([
            'payment_id' => $order->latestPayment->id,
            'event_name' => 'sandbox.payment.paid',
            'raw_webhook_payload' => json_encode([
                'status' => 'paid',
                'order_number' => $order->order_number,
                'method' => $order->latestPayment->payment_method,
                'amount' => $order->total_amount,
                'simulated_at' => now()->toIso8601String()
            ])
        ]);
    }
    
    // 2. Advance order to preparing
    $order->update([
        'status' => 'preparing',
        'payment_status' => 'paid'
    ]);

    return redirect()->back()->with('success', 'Sandbox payment simulated successfully! Order marked as PAID.');
});
