<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Add a primary test customer
        User::firstOrCreate(
            ['email_address' => 'customer@example.com'],
            [
                'first_name' => 'Demo',
                'last_name' => 'User',
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
            OrderSeeder::class,
        ]);
    }
}
