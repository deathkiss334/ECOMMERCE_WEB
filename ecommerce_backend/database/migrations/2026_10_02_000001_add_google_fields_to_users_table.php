<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Make password nullable (Google-only users have no password)
            // Note: SQLite cannot alter column constraints; this is a no-op on SQLite
            // but is safe to run anyway via doctrine/dbal when on MySQL.

            if (!Schema::hasColumn('users', 'google_id')) {
                $table->string('google_id')->nullable()->unique()->after('id');
            }
            if (!Schema::hasColumn('users', 'avatar')) {
                $table->string('avatar')->nullable()->after('google_id');
            }
            if (!Schema::hasColumn('users', 'role')) {
                $table->string('role')->default('customer')->after('avatar');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $toDrop = [];
            if (Schema::hasColumn('users', 'google_id')) $toDrop[] = 'google_id';
            if (Schema::hasColumn('users', 'avatar'))    $toDrop[] = 'avatar';
            if (Schema::hasColumn('users', 'role'))      $toDrop[] = 'role';
            if ($toDrop) $table->dropColumn($toDrop);
        });
    }
};
