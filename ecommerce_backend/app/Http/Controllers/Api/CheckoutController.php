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
                'gateway' => $validated['payment_method'] === 'cod' ? 'cod' : 'qr_payment',
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
                    'total_amount' => $totalAmount,
                    'message' => 'Order placed successfully via Cash on Delivery.'
                ]);
            }

            // 5B. Dynamic QR Code Payment (GCash, Maya, Any Bank App)
            $qrData = "ORDER:{$order->order_number}|PHP:{$totalAmount}|MERCHANT:FILIPINO-CUISINE-DASMARINAS";
            $qrImageUrl = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=" . urlencode($qrData);

            return response()->json([
                'success' => true,
                'order_number' => $order->order_number,
                'total_amount' => (float)$totalAmount,
                'payment_method' => $validated['payment_method'],
                'qr_image_url' => $qrImageUrl,
                'message' => 'Scan QR Code using GCash, Maya, or any mobile banking app.'
            ]);
        });
    }
}
