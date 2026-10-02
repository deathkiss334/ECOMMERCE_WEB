<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('product_table') && !Schema::hasColumn('product_table', 'product_image')) {
            Schema::table('product_table', function (Blueprint $table) {
                $table->text('product_image')->nullable();
            });
        }
    }

    public function down(): void
    {
        Schema::table('product_table', function (Blueprint $table) {
            $table->dropColumn('product_image');
        });
    }
};