<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\ProductVariant;
use Illuminate\Support\Str;

class OrderSeeder extends Seeder
{
    public function run(): void
    {
        $adobo = ProductVariant::where('sku', 'LIKE', '%ADOBO%')->first();
        $tea = ProductVariant::where('sku', 'UBE-MT-REG')->first();

        if (!$adobo) return;

        // Sample Order 1: Delivered
        $order1 = Order::firstOrCreate(
            ['order_number' => 'ORD-DEMO001'],
            [
                'user_id' => 1,
                'status' => 'delivered',
                'payment_status' => 'paid',
                'subtotal' => 250.00,
                'delivery_fee' => 39.00,
                'total_amount' => 289.00,
                'notes' => "Deliver to: Block 4 Lot 12, Dasmariñas, Cavite (09171234567)\n[Special Instructions: Extra spicy sauce please]",
            ]
        );

        OrderItem::firstOrCreate(
            ['order_id' => $order1->id, 'product_variant_id' => $adobo->id],
            [
                'product_name_snapshot' => 'Classic Chicken Adobo Meal',
                'variant_name_snapshot' => 'Standard Servings',
                'unit_price' => 140.00,
                'quantity' => 1,
                'total_price' => 140.00,
            ]
        );

        if ($tea) {
            OrderItem::firstOrCreate(
                ['order_id' => $order1->id, 'product_variant_id' => $tea->id],
                [
                    'product_name_snapshot' => 'Ube Milk Tea',
                    'variant_name_snapshot' => 'Regular (16oz)',
                    'unit_price' => 110.00,
                    'quantity' => 1,
                    'total_price' => 110.00,
                ]
            );
        }

        Payment::firstOrCreate(
            ['order_id' => $order1->id],
            [
                'id' => (string) Str::uuid(),
                'payment_method' => 'gcash',
                'gateway' => 'paymongo',
                'gateway_reference_id' => 'pay_demo_gcash_001',
                'amount' => 289.00,
                'status' => 'succeeded',
            ]
        );

        // Sample Order 2: In Preparation
        $order2 = Order::firstOrCreate(
            ['order_number' => 'ORD-DEMO002'],
            [
                'user_id' => 1,
                'status' => 'preparing',
                'payment_status' => 'paid',
                'subtotal' => 140.00,
                'delivery_fee' => 39.00,
                'total_amount' => 179.00,
                'notes' => "Deliver to: DBB-1 Dasmariñas, Cavite (09189876543)",
            ]
        );

        OrderItem::firstOrCreate(
            ['order_id' => $order2->id, 'product_variant_id' => $adobo->id],
            [
                'product_name_snapshot' => 'Classic Chicken Adobo Meal',
                'variant_name_snapshot' => 'Standard Servings',
                'unit_price' => 140.00,
                'quantity' => 1,
                'total_price' => 140.00,
            ]
        );

        Payment::firstOrCreate(
            ['order_id' => $order2->id],
            [
                'id' => (string) Str::uuid(),
                'payment_method' => 'maya',
                'gateway' => 'paymongo',
                'gateway_reference_id' => 'pay_demo_maya_002',
                'amount' => 179.00,
                'status' => 'succeeded',
            ]
        );
    }
}
