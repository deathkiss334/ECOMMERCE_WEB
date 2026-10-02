<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasTable('users')) {
            return;
        }

        // Check if users already has password_hash column
        $hasPasswordHash = Schema::hasColumn('users', 'password_hash');
        $hasPassword = Schema::hasColumn('users', 'password');

        if ($hasPasswordHash && !$hasPassword) {
            // Table already upgraded
            return;
        }

        DB::statement('PRAGMA foreign_keys=OFF;');

        DB::statement("
            CREATE TABLE IF NOT EXISTS users_temp (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email TEXT UNIQUE NOT NULL COLLATE NOCASE,
                password_hash TEXT NULL,
                name TEXT NOT NULL,
                phone TEXT NULL,
                role TEXT NOT NULL DEFAULT 'customer' CHECK(role IN ('customer', 'admin')),
                auth_provider TEXT NOT NULL DEFAULT 'local' CHECK(auth_provider IN ('local', 'google')),
                google_id TEXT UNIQUE NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        ");

        $pwdColumn = $hasPassword ? 'password' : 'password_hash';
        $googleColumn = Schema::hasColumn('users', 'google_id') ? 'google_id' : 'NULL';

        DB::statement("
            INSERT INTO users_temp (id, email, password_hash, name, phone, role, auth_provider, google_id, created_at, updated_at)
            SELECT 
                id, 
                LOWER(TRIM(email)), 
                {$pwdColumn}, 
                name, 
                NULL, 
                CASE WHEN role = 'admin' THEN 'admin' ELSE 'customer' END, 
                CASE WHEN {$googleColumn} IS NOT NULL AND {$googleColumn} != '' THEN 'google' ELSE 'local' END, 
                {$googleColumn}, 
                COALESCE(created_at, CURRENT_TIMESTAMP), 
                COALESCE(updated_at, CURRENT_TIMESTAMP) 
            FROM users;
        ");

        DB::statement("DROP TABLE users;");
        DB::statement("ALTER TABLE users_temp RENAME TO users;");

        DB::statement("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email);");
        DB::statement("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id);");
        DB::statement("CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);");

        DB::statement('PRAGMA foreign_keys=ON;');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
    }
};
