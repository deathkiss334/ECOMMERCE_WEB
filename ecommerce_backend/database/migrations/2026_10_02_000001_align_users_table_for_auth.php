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
        // No-op: users table already has all required columns
        // from 0001_01_01_000000_create_users_table.php
    }

    public function down(): void
    {
        //
    }
};
