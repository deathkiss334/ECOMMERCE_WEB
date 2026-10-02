<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\ProductTable;

class ProductTableSeeder extends Seeder
{
    public function run(): void
    {
        $products = [
            [
                'product_id' => '1',
                'product_quantity' => 50,
                'product_type' => 'Chicken Inasal',
                'product_price' => 189.00,
            ],
            [
                'product_id' => '2',
                'product_quantity' => 30,
                'product_type' => 'Pork Sisig',
                'product_price' => 220.00,
            ],
            [
                'product_id' => '3',
                'product_quantity' => 45,
                'product_type' => 'Beef Bulalo',
                'product_price' => 350.00,
            ],
            [
                'product_id' => '4',
                'product_quantity' => 20,
                'product_type' => 'Halo-Halo Special',
                'product_price' => 120.00,
            ],
            [
                'product_id' => '5',
                'product_quantity' => 60,
                'product_type' => 'Kare-Kare',
                'product_price' => 290.00,
            ],
        ];

        foreach ($products as $data) {
            ProductTable::updateOrCreate(['product_id' => $data['product_id']], $data);
        }
    }
}
