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
                'product_description' => 'Grilled chicken marinated in lemongrass, calamansi, and spices.',
                'product_price' => 189.00,
                'product_image' => 'assets/food1.jpg',
            ],
            [
                'product_id' => '2',
                'product_quantity' => 30,
                'product_type' => 'Pork Sisig',
                'product_description' => 'Sizzling minced pork topped with calamansi and chili peppers.',
                'product_price' => 220.00,
                'product_image' => 'assets/food2.jpg',
            ],
            [
                'product_id' => '3',
                'product_quantity' => 45,
                'product_type' => 'Beef Bulalo',
                'product_description' => 'Traditional beef shank soup with bone marrow and fresh vegetables.',
                'product_price' => 350.00,
                'product_image' => 'assets/food3.jpg',
            ],
            [
                'product_id' => '4',
                'product_quantity' => 20,
                'product_type' => 'Halo-Halo Special',
                'product_description' => 'Shaved ice dessert with sweet beans, saba, ube, and leche flan.',
                'product_price' => 120.00,
                'product_image' => 'assets/food1.jpg',
            ],
            [
                'product_id' => '5',
                'product_quantity' => 60,
                'product_type' => 'Kare-Kare',
                'product_description' => 'Rich peanut stew with oxtail, beef tripe, and eggplant.',
                'product_price' => 290.00,
                'product_image' => 'assets/food2.jpg',
            ],
        ];

        foreach ($products as $data) {
            ProductTable::updateOrCreate(['product_id' => $data['product_id']], $data);
        }
    }
}
