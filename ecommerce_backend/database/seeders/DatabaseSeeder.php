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
        // Add a primary test customer
        User::firstOrCreate(
            ['email' => 'customer@example.com'],
            [
                'name' => 'Demo User',
                'password_hash' => Hash::make('Customer@12345'),
                'phone' => '09123456789',
                'role' => 'customer',
                'auth_provider' => 'local',
            ]
        );

        // Add default System Administrator account
        User::firstOrCreate(
            ['email' => 'admin@example.com'],
            [
                'name' => 'System Admin',
                'password_hash' => Hash::make('Admin@12345'),
                'phone' => '09990001111',
                'role' => 'admin',
                'auth_provider' => 'local',
            ]
        );

        $this->call([
            StoreDataSeeder::class,
            ProductTableSeeder::class,
        ]);
    }
}
