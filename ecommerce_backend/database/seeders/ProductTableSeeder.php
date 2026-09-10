<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\ProductTable;
use App\Services\FirebaseService;

class ProductTableSeeder extends Seeder
{
    public function run(): void
    {
        $products = [
            [
                'product_id' => 'PROD-101',
                'product_quantity' => 50,
                'product_type' => 'Chicken Inasal',
                'product_price' => 189.00,
            ],
            [
                'product_id' => 'PROD-102',
                'product_quantity' => 30,
                'product_type' => 'Pork Sisig',
                'product_price' => 220.00,
            ],
            [
                'product_id' => 'PROD-103',
                'product_quantity' => 45,
                'product_type' => 'Beef Bulalo',
                'product_price' => 350.00,
            ],
            [
                'product_id' => 'PROD-104',
                'product_quantity' => 20,
                'product_type' => 'Halo-Halo Special',
                'product_price' => 120.00,
            ],
            [
                'product_id' => 'PROD-105',
                'product_quantity' => 60,
                'product_type' => 'Kare-Kare',
                'product_price' => 290.00,
            ],
        ];

        foreach ($products as $data) {
            $product = ProductTable::updateOrCreate(
                ['product_id' => $data['product_id']],
                $data
            );

            // Sync to Firebase Cloud Firestore product_table collection
            FirebaseService::syncProductTable($product);
        }
    }
}
