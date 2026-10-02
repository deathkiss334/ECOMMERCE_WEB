<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\ProductVariant;
use App\Services\FirebaseService;

class CheckoutController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'items' => 'required|array',
            'items.*.id' => 'required|exists:product_variants,id',
            'items.*.qty' => 'required|integer|min:1',
            'payment_method' => 'required|string', 
            'customer_name' => 'required|string|max:120',
            'customer_email' => 'nullable|string|max:150',
            'email_address' => 'nullable|string|max:150',
            'customer_phone' => 'nullable|string|max:30',
            'phone' => 'nullable|string|max:30',
            'delivery_address' => 'nullable|string',
            'order_type' => 'nullable|string|in:DELIVERY,DINE_IN,delivery,dine_in,pickup,PICKUP',
        ]);
        $orderType = strtoupper($validated['order_type'] ?? 'DELIVERY');
        if ($orderType === 'PICKUP') $orderType = 'DINE_IN';

        return DB::transaction(function () use ($validated, $orderType) {
            $totalAmount = 0;
            $orderItems = [];

            // 1. Calculate total securely from the database
            foreach ($validated['items'] as $item) {
                $variant = ProductVariant::with('product')->findOrFail($item['id']);
                $price = $variant->price ?? $variant->product->base_price;
                $lineTotal = $price * $item['qty'];
                $totalAmount += $lineTotal;

                $orderItems[] = [
                    'product_variant_id' => $variant->id,
                    'product_name_snapshot' => $variant->product->name,
                    'variant_name_snapshot' => $variant->name,
                    'unit_price' => $price,
                    'quantity' => $item['qty'],
                    'total_price' => $lineTotal,
                ];
            }

            $userId = auth('sanctum')->id() ?? 1;
            $address = $orderType === 'DINE_IN' ? 'Dine-in (Store)' : ($validated['delivery_address'] ?? 'Dine-in (Store)');
            $phone = $validated['customer_phone'] ?? $validated['phone'] ?? '';
            $email = $validated['customer_email'] ?? $validated['email_address'] ?? '';
            $notes = $orderType === 'DINE_IN' ? 'Dine-in Order' : ('Deliver to: ' . $address . ($phone ? " ($phone)" : ''));

            // 2. Create Order in PAYMENT_PENDING status
            $orderNumber = 'DASMA-' . strtoupper(Str::random(6));
            $order = Order::create([
                'order_number' => $orderNumber,
                'user_id' => $userId,
                'customer_name' => $validated['customer_name'],
                'customer_email' => $email,
                'order_type' => $orderType,
                'status' => $validated['payment_method'] === 'cod' ? 'PREPARING' : 'PAYMENT_PENDING',
                'payment_status' => 'unpaid',
                'subtotal' => $totalAmount,
                'total_amount' => $totalAmount, 
                'notes' => $notes,
            ]);

            // 3. Attach Items to Order
            foreach ($orderItems as $oi) {
                $oi['order_id'] = $order->id;
                OrderItem::create($oi);
            }

            // 4. Create Initial Payment Record
            $payment = Payment::create([
                'id' => (string) Str::uuid(),
                'order_id' => $order->id,
                'payment_method' => $validated['payment_method'],
                'gateway' => $validated['payment_method'] === 'cod' ? 'cod' : 'gcash_manual',
                'amount' => $totalAmount,
                'status' => 'pending',
            ]);

            // 5A. Handle Cash On Delivery
            if ($validated['payment_method'] === 'cod') {
            
                return response()->json([
                    'success' => true,
                    'orderId' => $order->order_number,
                    'order_number' => $order->order_number,
                    'totalAmount' => (float) $totalAmount,
                    'total_amount' => (float) $totalAmount,
                    'payment_method' => 'cod',
                    'status' => 'PREPARING',
                    'payment_status' => 'unpaid',
                    'message' => 'Order placed successfully via Cash on Delivery. Preparing now.'
                ]);
            }

            // 5B. Manual GCash QR Payment
            $qrImageUrl = asset('assets/gcash_qr.png');

    

            return response()->json([
                'success' => true,
                'orderId' => $order->order_number,
                'order_number' => $order->order_number,
                'totalAmount' => (float) $totalAmount,
                'total_amount' => (float) $totalAmount,
                'payment_method' => $validated['payment_method'],
                'account_name' => 'R** SA***L M.',
                'account_number' => '+63 985 564 4297',
                'qr_image_url' => $qrImageUrl,
                'status' => 'PAYMENT_PENDING',
                'payment_status' => 'unpaid',
                'message' => 'Please scan GCash QR code, send exactly ₱' . number_format($totalAmount, 2) . ', and upload receipt proof.'
            ], 201);
        });
    }
}
