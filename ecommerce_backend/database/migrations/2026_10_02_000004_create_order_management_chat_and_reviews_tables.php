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
        // 1. Ensure orders table has all order management fields
        if (Schema::hasTable('orders')) {
            Schema::table('orders', function (Blueprint $table) {
                if (!Schema::hasColumn('orders', 'customer_name')) {
                    $table->string('customer_name')->nullable();
                }
                if (!Schema::hasColumn('orders', 'customer_email')) {
                    $table->string('customer_email')->nullable();
                }
                if (!Schema::hasColumn('orders', 'order_type')) {
                    $table->string('order_type')->default('DELIVERY');
                }
                if (!Schema::hasColumn('orders', 'rejection_reason')) {
                    $table->text('rejection_reason')->nullable();
                }
            });
        }

        // 2. Chat Messages (Admin <-> Customer per Order)
        if (!Schema::hasTable('order_chats')) {
            Schema::create('order_chats', function (Blueprint $table) {
                $table->id();
                $table->string('order_id');
                $table->string('sender_role'); // 'customer' or 'admin'
                $table->string('sender_name');
                $table->text('message');
                $table->timestamps();

                $table->index('order_id');
            });
        }

        // 3. Order Reviews & Ratings Table
        if (!Schema::hasTable('order_reviews')) {
            Schema::create('order_reviews', function (Blueprint $table) {
                $table->id();
                $table->string('order_id');
                $table->unsignedBigInteger('user_id')->nullable();
                $table->tinyInteger('rating')->default(5);
                $table->text('feedback')->nullable();
                $table->timestamps();

                $table->unique('order_id');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_reviews');
        Schema::dropIfExists('order_chats');
    }
};
