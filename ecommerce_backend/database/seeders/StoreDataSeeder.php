<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductVariant;

class StoreDataSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Core Categories
        $categories = [
            ['name' => 'Meals & Combos', 'slug' => 'meals-combos', 'icon_url' => 'assets/icons/meal.png'],
            ['name' => 'Snacks & Sides', 'slug' => 'snacks-sides', 'icon_url' => 'assets/icons/snack.png'],
            ['name' => 'Beverages', 'slug' => 'beverages', 'icon_url' => 'assets/icons/drink.png'],
            ['name' => 'Desserts', 'slug' => 'desserts', 'icon_url' => 'assets/icons/dessert.png'],
        ];

        foreach ($categories as $catData) {
            Category::firstOrCreate(['slug' => $catData['slug']], $catData);
        }

        $mealsId = Category::where('slug', 'meals-combos')->first()->id;
        $beverageId = Category::where('slug', 'beverages')->first()->id;

        // 2. Filipino Favorites (Excluding Nearby Restaurants logic explicitly)
        $products = [
            [
                'category_id' => $mealsId,
                'name' => 'Classic Chicken Adobo Meal',
                'slug' => 'classic-chicken-adobo',
                'description' => 'Savory soy-garlic chicken adobo served with steamed white rice.',
                'base_price' => 140.00,
                'rating_avg' => 4.8,
                'total_reviews' => 124,
                'is_featured' => true,
            ],
            [
                'category_id' => $mealsId,
                'name' => 'Pork Sisig Rice Bowl',
                'slug' => 'pork-sisig-rice-bowl',
                'description' => 'Sizzling pork sisig topped with chicharron bits and egg on a bed of rice.',
                'base_price' => 155.00,
                'rating_avg' => 4.9,
                'total_reviews' => 89,
                'is_featured' => true,
            ],
            [
                'category_id' => $beverageId,
                'name' => 'Ube Milk Tea',
                'slug' => 'ube-milk-tea',
                'description' => 'Sweet and creamy purple yam milk tea with chewy boba pearls.',
                'base_price' => 110.00,
                'rating_avg' => 4.7,
                'total_reviews' => 205,
                'is_featured' => false,
            ]
        ];

        foreach ($products as $prodData) {
            $product = Product::firstOrCreate(['slug' => $prodData['slug']], $prodData);
            
            // Create variations
            if ($prodData['slug'] === 'ube-milk-tea') {
                ProductVariant::firstOrCreate(['sku' => 'UBE-MT-REG'], [
                    'product_id' => $product->id,
                    'name' => 'Regular (16oz)',
                    'price' => 110.00,
                    'stock_quantity' => 100
                ]);
                ProductVariant::firstOrCreate(['sku' => 'UBE-MT-LRG'], [
                    'product_id' => $product->id,
                    'name' => 'Large (22oz)',
                    'price' => 135.00,
                    'stock_quantity' => 100
                ]);
            } else {
                ProductVariant::firstOrCreate(['sku' => strtoupper(Str::slug($prodData['name'])) . '-STD'], [
                    'product_id' => $product->id,
                    'name' => 'Standard Servings',
                    'price' => $prodData['base_price'],
                    'stock_quantity' => 50
                ]);
            }
        }
    }
}
