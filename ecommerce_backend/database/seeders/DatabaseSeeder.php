<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use Database\Seeders\StoreDataSeeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Add a primary test user
        User::firstOrCreate(
            ['email' => 'customer@example.com'],
            [
                'name' => 'Demo User',
                'password' => Hash::make('password')
            ]
        );

        $this->call([
            StoreDataSeeder::class,
            ProductTableSeeder::class,
        ]);
    }
}
