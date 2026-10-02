<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use Illuminate\Support\Str;

class OrderSeeder extends Seeder
{
    public function run(): void
    {
        $adobo = Product::where('product_name', 'LIKE', '%Adobo%')->first() 
              ?? Product::firstOrCreate(['product_name' => 'Classic Chicken Adobo Meal'], [
                    'product_price' => 140.00,
                    'product_qty' => 50,
                    'product_category' => 'Meals & Combos'
                ]);

        // Sample Order 1: Delivered
        $order1 = Order::firstOrCreate(
            ['order_number' => 'ORD-DEMO001'],
            [
                'customer_id' => 1,
                'user_id' => 1,
                'payment_method' => 'gcash',
                'total_paid' => 289.00,
                'total_amount' => 289.00,
                'subtotal' => 250.00,
                'delivery_fee' => 39.00,
                'order_type' => 'takeout',
                'status' => 'delivered',
                'payment_status' => 'paid',
                'notes' => "Deliver to: Block 4 Lot 12, Dasmariñas, Cavite (09171234567)\n[Special Instructions: Extra spicy sauce please]",
            ]
        );

        OrderItem::firstOrCreate(
            ['order_id' => $order1->order_id, 'product_name' => 'Classic Chicken Adobo Meal'],
            [
                'product_id' => $adobo->product_id,
                'quantity' => 1,
                'unit_price' => 140.00,
                'subtotal' => 140.00,
                'total_price' => 140.00,
                'product_name_snapshot' => 'Classic Chicken Adobo Meal',
                'variant_name_snapshot' => 'Standard Servings',
            ]
        );

        Payment::firstOrCreate(
            ['payment_id' => 'pay_demo_gcash_001'],
            [
                'order_id' => $order1->order_id,
                'payment_method' => 'gcash',
                'amount' => 289.00,
                'transaction_id' => 'TXN-GCASH-9912',
                'payment_status' => 'succeeded',
                'gateway' => 'paymongo',
                'status' => 'succeeded',
            ]
        );
    }
}
