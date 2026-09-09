<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\Payment;
use App\Models\PaymentTransaction;
use App\Services\FirebaseService;

class QrPaymentController extends Controller
{
    /**
     * Confirm a QR code scan payment from the customer.
     */
    public function confirm(Request $request)
    {
        $validated = $request->validate([
            'order_number' => 'required|string|exists:orders,order_number',
            'reference_number' => 'nullable|string',
            'payment_method' => 'nullable|string',
        ]);

        $order = Order::with('latestPayment')->where('order_number', $validated['order_number'])->firstOrFail();

        // 1. Update or create payment record
        if ($order->latestPayment) {
            $order->latestPayment->update([
                'status' => 'succeeded',
                'gateway_reference_id' => $validated['reference_number'] ?? ('QR-REF-' . time()),
            ]);
        }

        // 2. Log transaction
        PaymentTransaction::create([
            'payment_id' => $order->latestPayment->id ?? $order->id,
            'event_name' => 'qr.payment.confirmed',
            'raw_webhook_payload' => json_encode([
                'order_number' => $order->order_number,
                'reference_number' => $validated['reference_number'] ?? 'QR-SCANNED',
                'amount' => $order->total_amount,
                'confirmed_at' => now()->toIso8601String(),
            ]),
        ]);

        // 3. Advance order to preparing
        $order->update([
            'status' => 'preparing',
            'payment_status' => 'paid',
        ]);

        // 4. Synchronize immediately to Firebase Firestore
        FirebaseService::syncOrder($order);

        return response()->json([
            'success' => true,
            'message' => 'Payment confirmed via QR Code! Order is now preparing.',
            'order_number' => $order->order_number,
            'status' => $order->status,
        ]);
    }
}
