<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Services\OrderService;

class CheckoutController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'items' => 'required|array|min:1',
            'items.*.id' => 'nullable',
            'items.*.qty' => 'nullable|integer|min:1',
            'items.*.quantity' => 'nullable|integer|min:1',
            'payment_method' => 'required|string',
            'customer_name' => 'required|string|max:120',
            'customer_email' => 'nullable|string|max:150',
            'email_address' => 'nullable|string|max:150',
            'email' => 'nullable|string|max:150',
            'customer_phone' => 'nullable|string|max:30',
            'delivery_address' => 'nullable|string',
            'order_type' => 'nullable|string|in:DELIVERY,DINE_IN,delivery,dine_in,pickup,PICKUP,takeout,TAKEOUT',
        ]);

        $resolvedEmail = $validated['customer_email'] 
            ?? $validated['email_address'] 
            ?? $validated['email'] 
            ?? $request->input('customer_email') 
            ?? $request->input('email_address') 
            ?? $request->input('email');
        if (!empty($resolvedEmail)) {
            $validated['customer_email'] = strtolower(trim($resolvedEmail));
        }

        $rawOrderType = strtoupper($validated['order_type'] ?? 'DELIVERY');
        $isDelivery = !in_array($rawOrderType, ['PICKUP', 'DINE_IN', 'DINE-IN', 'TAKEOUT']);

        if (!$isDelivery && strtolower($validated['payment_method']) === 'cod') {
            return response()->json([
                'success' => false,
                'message' => 'Dine-In orders require upfront payment (GCash QR) before preparation to prevent unserved orders.',
                'error' => 'PAY_FIRST_REQUIRED',
            ], 422);
        }

        $order = OrderService::createOrder($validated);
        $totalAmount = (float) $order['total_amount'];

        if (strtolower($validated['payment_method']) === 'cod') {
            return response()->json([
                'success' => true,
                'orderId' => $order['order_number'],
                'order_number' => $order['order_number'],
                'order_id' => $order['order_id'],
                'totalAmount' => $totalAmount,
                'total_amount' => $totalAmount,
                'payment_method' => 'cod',
                'status' => 'PREPARING',
                'payment_status' => 'unpaid',
                'order' => $order,
                'message' => 'Order placed successfully via Cash on Delivery. Preparing now.'
            ], 201);
        }

        // Manual GCash QR Payment
        $qrImageUrl = asset('assets/gcash_qr.png');

        return response()->json([
            'success' => true,
            'orderId' => $order['order_number'],
            'order_number' => $order['order_number'],
            'order_id' => $order['order_id'],
            'totalAmount' => $totalAmount,
            'total_amount' => $totalAmount,
            'payment_method' => $validated['payment_method'],
            'account_name' => 'R** SA***L M.',
            'account_number' => '+63 985 564 4297',
            'qr_image_url' => $qrImageUrl,
            'status' => 'PAYMENT_PENDING',
            'payment_status' => 'unpaid',
            'order' => $order,
            'message' => 'Please scan GCash QR code, send exactly ₱' . number_format($totalAmount, 2) . ', and upload receipt proof.'
        ], 200);
    }
}
