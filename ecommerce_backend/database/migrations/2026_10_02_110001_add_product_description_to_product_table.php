<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('product_table', function (Blueprint $table) {
            $table->text('product_description')->nullable()->after('product_type');
        });
    }

    public function down(): void
    {
        Schema::table('product_table', function (Blueprint $table) {
            $table->dropColumn('product_description');
        });
    }
};