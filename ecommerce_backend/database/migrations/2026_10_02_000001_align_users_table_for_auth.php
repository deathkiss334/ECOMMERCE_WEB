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

        $idColumn = Schema::hasColumn('users', 'user_id') ? 'user_id' : (Schema::hasColumn('users', 'id') ? 'id' : 'rowid');
        $emailColumn = Schema::hasColumn('users', 'email_address') ? 'email_address' : 'email';
        $pwdColumn = Schema::hasColumn('users', 'password_hash') ? 'password_hash' : (Schema::hasColumn('users', 'password') ? 'password' : 'NULL');
        $googleColumn = Schema::hasColumn('users', 'google_id') ? 'google_id' : 'NULL';

        // Check if users already aligned
        if (Schema::hasColumn('users', 'user_id') && Schema::hasColumn('users', 'password_hash') && Schema::hasColumn('users', 'first_name')) {
            return;
        }

        DB::statement('PRAGMA foreign_keys=OFF;');

        DB::statement("
            CREATE TABLE IF NOT EXISTS users_temp (
                user_id INTEGER PRIMARY KEY AUTOINCREMENT,
                first_name TEXT NULL,
                last_name TEXT NULL,
                birthday TEXT NULL,
                address TEXT NULL,
                phone_num TEXT NULL,
                email_address TEXT UNIQUE NULL,
                password TEXT NULL,
                name TEXT NULL,
                email TEXT NULL,
                password_hash TEXT NULL,
                phone TEXT NULL,
                role TEXT NOT NULL DEFAULT 'customer',
                auth_provider TEXT NOT NULL DEFAULT 'local',
                google_id TEXT NULL,
                remember_token TEXT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        ");

        $pwdColumn = $hasPassword ? 'password' : 'password_hash';
        $googleColumn = Schema::hasColumn('users', 'google_id') ? 'google_id' : 'NULL';
        $roleExpr = Schema::hasColumn('users', 'role') 
            ? "CASE WHEN role = 'admin' THEN 'admin' ELSE 'customer' END" 
            : "'customer'";

        DB::statement("
            INSERT INTO users_temp (user_id, email_address, email, password_hash, password, name, phone_num, role, auth_provider, google_id, created_at, updated_at)
            SELECT 
                {$idColumn}, 
                LOWER(TRIM({$emailColumn})), 
                LOWER(TRIM({$emailColumn})), 
                {$pwdColumn}, 
                {$pwdColumn}, 
                COALESCE(name, 'User'), 
                NULL, 
                {$roleExpr}, 
                CASE WHEN {$googleColumn} IS NOT NULL AND {$googleColumn} != '' THEN 'google' ELSE 'local' END, 
                {$googleColumn}, 
                COALESCE(created_at, CURRENT_TIMESTAMP), 
                COALESCE(updated_at, CURRENT_TIMESTAMP) 
            FROM users;
        ");

        DB::statement("DROP TABLE users;");
        DB::statement("ALTER TABLE users_temp RENAME TO users;");

        DB::statement('PRAGMA foreign_keys=ON;');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
    }
};
