<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Migration: Fix users table to use user_id as primary key.
 *
 * Safe to run even if the table was modified by groupmates.
 * Uses raw SQL for PostgreSQL (Supabase) compatibility.
 */
return new class extends Migration
{
    public function up(): void
    {
        // Nothing to do if users table doesn't exist yet
        if (!Schema::hasTable('users')) {
            return;
        }

        $driver = DB::getDriverName();

        // ── Step 1: Ensure user_id column exists ─────────────────────────────
        if (!Schema::hasColumn('users', 'user_id')) {
            if ($driver === 'pgsql') {
                // Add user_id as a bigserial (auto-increment) in PostgreSQL
                DB::statement('ALTER TABLE users ADD COLUMN user_id BIGSERIAL');
            } else {
                Schema::table('users', function (Blueprint $table) {
                    $table->id('user_id');
                });
            }
        }

        // ── Step 2: Drop existing primary key if it is NOT user_id ───────────
        if ($driver === 'pgsql') {
            // Detect the current primary key column
            $pkResult = DB::select("
                SELECT kcu.column_name
                FROM information_schema.table_constraints AS tc
                JOIN information_schema.key_column_usage AS kcu
                    ON tc.constraint_name = kcu.constraint_name
                    AND tc.table_schema = kcu.table_schema
                WHERE tc.constraint_type = 'PRIMARY KEY'
                  AND tc.table_name = 'users'
                  AND tc.table_schema = 'public'
            ");

            $currentPkColumn = $pkResult[0]->column_name ?? null;

            if ($currentPkColumn && $currentPkColumn !== 'user_id') {
                // Get constraint name
                $constraintResult = DB::select("
                    SELECT tc.constraint_name
                    FROM information_schema.table_constraints AS tc
                    WHERE tc.constraint_type = 'PRIMARY KEY'
                      AND tc.table_name = 'users'
                      AND tc.table_schema = 'public'
                ");
                $constraintName = $constraintResult[0]->constraint_name ?? null;

                if ($constraintName) {
                    DB::statement("ALTER TABLE users DROP CONSTRAINT \"{$constraintName}\"");
                }

                // Set user_id as new primary key
                DB::statement('ALTER TABLE users ADD PRIMARY KEY (user_id)');

            } elseif (!$currentPkColumn) {
                // No primary key at all — set user_id
                DB::statement('ALTER TABLE users ADD PRIMARY KEY (user_id)');
            }

            // ── Step 3: Ensure required auth columns exist ───────────────────
            $authColumns = [
                'name'           => "ALTER TABLE users ADD COLUMN IF NOT EXISTS name VARCHAR(255)",
                'email'          => "ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255)",
                'password_hash'  => "ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255)",
                'phone'          => "ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(50)",
                'role'           => "ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'customer'",
                'auth_provider'  => "ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(50) DEFAULT 'local'",
                'google_id'      => "ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR(255)",
                'remember_token' => "ALTER TABLE users ADD COLUMN IF NOT EXISTS remember_token VARCHAR(100)",
                'created_at'     => "ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ",
                'updated_at'     => "ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ",
            ];

            foreach ($authColumns as $col => $sql) {
                if (!Schema::hasColumn('users', $col)) {
                    DB::statement($sql);
                }
            }

            // Ensure email has a unique index
            if (Schema::hasColumn('users', 'email')) {
                try {
                    DB::statement('CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique ON users (email)');
                } catch (\Throwable $e) {
                    // Index might already exist under a different name — skip
                }
            }
        }
    }

    public function down(): void
    {
        // Non-destructive — we don't revert primary key changes
    }
};
