<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

/**
 * This migration was originally a SQLite-specific table rebuild.
 * Replaced with a no-op since we are now on Supabase PostgreSQL
 * and the users table is created correctly in the base migration.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('users')) {
            return;
        }

        // Check if users already aligned
        if (Schema::hasColumn('users', 'user_id') && Schema::hasColumn('users', 'password_hash') && Schema::hasColumn('users', 'first_name')) {
            return;
        }

        // For PostgreSQL (Supabase), use ALTER TABLE to add missing columns
        // instead of the SQLite temp-table swap pattern
        $columnsToAdd = [
            'first_name'    => 'string',
            'last_name'     => 'string',
            'birthday'      => 'string',
            'address'       => 'text',
            'phone_num'     => 'string',
            'email_address' => 'string',
            'password'      => 'string',
            'name'          => 'string',
            'email'         => 'string',
            'password_hash' => 'string',
            'phone'         => 'string',
            'role'          => 'string',
            'auth_provider' => 'string',
            'google_id'     => 'string',
        ];

        Schema::table('users', function (Blueprint $table) use ($columnsToAdd) {
            foreach ($columnsToAdd as $col => $type) {
                if (!Schema::hasColumn('users', $col)) {
                    if ($col === 'role') {
                        $table->string($col)->default('customer')->nullable();
                    } elseif ($col === 'auth_provider') {
                        $table->string($col)->default('local')->nullable();
                    } else {
                        $table->{$type}($col)->nullable();
                    }
                }
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
