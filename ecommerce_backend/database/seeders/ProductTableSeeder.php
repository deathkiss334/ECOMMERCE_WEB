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
                'product_name' => 'Chicken Inasal',
                'product_qty' => 50,
                'product_category' => 'Meals & Combos',
                'product_price' => 189.00,
                'product_desc' => 'Grilled chicken marinated in lemongrass, calamansi, and spices.',
                'product_rating' => 4.8,
            ],
            [
                'product_name' => 'Pork Sisig',
                'product_qty' => 30,
                'product_category' => 'Meals & Combos',
                'product_price' => 220.00,
                'product_desc' => 'Sizzling minced pork topped with calamansi and chili peppers.',
                'product_rating' => 4.9,
            ],
            [
                'product_name' => 'Beef Bulalo',
                'product_qty' => 45,
                'product_category' => 'Meals & Combos',
                'product_price' => 350.00,
                'product_desc' => 'Traditional beef shank soup with bone marrow and fresh vegetables.',
                'product_rating' => 4.7,
            ],
            [
                'product_name' => 'Halo-Halo Special',
                'product_qty' => 20,
                'product_category' => 'Desserts',
                'product_price' => 120.00,
                'product_desc' => 'Shaved ice dessert with sweet beans, saba, ube, and leche flan.',
                'product_rating' => 4.9,
            ],
            [
                'product_name' => 'Kare-Kare',
                'product_qty' => 60,
                'product_category' => 'Meals & Combos',
                'product_price' => 290.00,
                'product_desc' => 'Rich peanut stew with oxtail, beef tripe, and eggplant.',
                'product_rating' => 4.6,
            ],
        ];

        foreach ($products as $data) {
            Product::updateOrCreate(
                ['product_name' => $data['product_name']],
                $data
            );
        }
    }
}
