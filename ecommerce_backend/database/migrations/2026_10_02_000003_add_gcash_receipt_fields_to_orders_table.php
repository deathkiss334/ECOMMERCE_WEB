<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'gcash_ref_number')) {
                $table->string('gcash_ref_number')->nullable()->after('payment_status');
            }
            if (!Schema::hasColumn('orders', 'receipt_image_url')) {
                $table->string('receipt_image_url')->nullable()->after('gcash_ref_number');
            }
            if (!Schema::hasColumn('orders', 'admin_notes')) {
                $table->text('admin_notes')->nullable()->after('receipt_image_url');
            }
            if (!Schema::hasColumn('orders', 'verified_at')) {
                $table->timestamp('verified_at')->nullable()->after('admin_notes');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['gcash_ref_number', 'receipt_image_url', 'admin_notes', 'verified_at']);
        });
    }
};
