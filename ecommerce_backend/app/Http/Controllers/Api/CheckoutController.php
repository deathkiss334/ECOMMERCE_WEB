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
            'customer_name' => 'required|string',
            'customer_phone' => 'required|string',
            'delivery_address' => 'required|string',
        ]);

        return DB::transaction(function () use ($validated) {
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

            // 2. Create the Order
            $order = Order::create([
                'order_number' => 'ORD-' . strtoupper(Str::random(8)),
                'user_id' => 1, // Defaulting to our seeded Demo User
                'status' => 'pending',
                'payment_status' => 'unpaid',
                'subtotal' => $totalAmount,
                'total_amount' => $totalAmount, 
                'notes' => 'Deliver to: ' . $validated['delivery_address'] . ' (' . $validated['customer_phone'] . ')',
            ]);

            // 3. Attach Items to Order
            foreach ($orderItems as $oi) {
                $oi['order_id'] = $order->id;
                OrderItem::create($oi);
            }

            // 4. Create Payment Ledger
            $payment = Payment::create([
                'id' => (string) Str::uuid(),
                'order_id' => $order->id,
                'payment_method' => $validated['payment_method'],
                'gateway' => clone($validated['payment_method']) === 'cod' ? 'cod' : 'paymongo',
                'amount' => $totalAmount,
                'status' => 'pending',
            ]);

            // Synchronize newly created order to Firebase
            FirebaseService::syncOrder($order);

            // 5A. Handle Cash On Delivery
            if ($validated['payment_method'] === 'cod') {
                $order->update(['status' => 'preparing']); // Immediately proceed with COD
                FirebaseService::syncOrder($order);
                return response()->json([
                    'success' => true,
                    'order_number' => $order->order_number,
                    'message' => 'Order placed successfully via Cash on Delivery.'
                ]);
            }

            // 5B. Handle E-Wallets / Cards via PayMongo
            $paymongoSecret = env('PAYMONGO_SECRET_KEY');
            
            if (!$paymongoSecret) {
                // Seamless Mock fallback for the Live Demo format requested in the presentation outline
                return response()->json([
                    'success' => true,
                    'order_number' => $order->order_number,
                    'checkout_url' => 'https://mock-paymongo.test/checkout/' . $order->order_number,
                    'message' => 'Mock payment link generated (Add PAYMONGO_SECRET_KEY to .env for real transactions).'
                ]);
            }

            // Real PayMongo Checkout Link Generation
            $response = Http::withBasicAuth($paymongoSecret, '')
                ->post('https://api.paymongo.com/v1/links', [
                    'data' => [
                        'attributes' => [
                            'amount' => (int) ($totalAmount * 100), // Configured in centavos
                            'description' => 'E-Commerce Order: ' . $order->order_number,
                            'remarks' => $order->order_number
                        ]
                    ]
                ]);

            if ($response->successful()) {
                $link = $response->json('data.attributes.checkout_url');
                $payment->update(['gateway_reference_id' => $response->json('data.id')]);
                
                return response()->json([
                    'success' => true,
                    'order_number' => $order->order_number,
                    'checkout_url' => $link
                ]);
            }

            return response()->json(['error' => 'Payment gateway connection failed', 'details' => $response->json()], 500);
        });
    }
}
