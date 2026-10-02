<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations for ERD compliance.
     */
    public function up(): void
    {
        // 1. USERS - ensure user_id column exists
        if (Schema::hasTable('users') && !Schema::hasColumn('users', 'user_id')) {
            Schema::table('users', function (Blueprint $table) {
                $table->id('user_id');
            });
        }

        // 2. PRODUCTS
        if (!Schema::hasTable('products')) {
            Schema::create('products', function (Blueprint $table) {
                $table->id('product_id');
                $table->string('product_name');
                $table->text('product_img')->nullable();
                $table->text('product_desc')->nullable();
                $table->integer('product_qty')->default(0);
                $table->decimal('product_rating', 3, 2)->default(0.00);
                $table->string('product_category')->nullable();
                $table->decimal('product_price', 10, 2)->default(0.00);
                $table->timestamps();
            });
        }

        // 3. CART
        if (!Schema::hasTable('cart')) {
            Schema::create('cart', function (Blueprint $table) {
                $table->id('cart_id');
                $table->unsignedBigInteger('user_id');
                $table->unsignedBigInteger('product_id');
                $table->integer('quantity')->default(1);
                $table->timestamps();

                $table->foreign('user_id')->references('user_id')->on('users')->cascadeOnDelete();
                $table->foreign('product_id')->references('product_id')->on('products')->cascadeOnDelete();
            });
        }

        // 4. ORDER_HEADER
        if (!Schema::hasTable('order_header')) {
            Schema::create('order_header', function (Blueprint $table) {
                $table->id('order_id');
                $table->unsignedBigInteger('customer_id');
                $table->string('payment_method')->nullable();
                $table->decimal('total_paid', 10, 2)->default(0.00);
                $table->string('order_type')->nullable();
                $table->timestamp('created_at')->nullable();

                $table->string('order_number')->nullable();
                $table->unsignedBigInteger('user_id')->nullable();
                $table->string('status')->default('pending');
                $table->string('payment_status')->default('unpaid');
                $table->decimal('subtotal', 10, 2)->default(0.00);
                $table->decimal('delivery_fee', 10, 2)->default(0.00);
                $table->decimal('total_amount', 10, 2)->default(0.00);
                $table->text('notes')->nullable();
                $table->string('gcash_reference_no')->nullable();
                $table->string('gcash_receipt_path')->nullable();
                $table->timestamp('updated_at')->nullable();

                $table->foreign('customer_id')->references('user_id')->on('users')->cascadeOnDelete();
            });
        }

        // 5. ORDER_DETAILS
        if (!Schema::hasTable('order_details')) {
            Schema::create('order_details', function (Blueprint $table) {
                $table->id('od_id');
                $table->unsignedBigInteger('order_id');
                $table->unsignedBigInteger('product_id')->nullable();
                $table->string('product_name');
                $table->integer('quantity')->default(1);
                $table->decimal('unit_price', 10, 2)->default(0.00);
                $table->decimal('subtotal', 10, 2)->default(0.00);

                $table->unsignedBigInteger('product_variant_id')->nullable();
                $table->string('product_name_snapshot')->nullable();
                $table->string('variant_name_snapshot')->nullable();
                $table->decimal('total_price', 10, 2)->default(0.00);
                $table->timestamps();

                $table->foreign('order_id')->references('order_id')->on('order_header')->cascadeOnDelete();
                $table->foreign('product_id')->references('product_id')->on('products')->nullOnDelete();
            });
        }

        // 6. PAYMENT_RECORD
        if (!Schema::hasTable('payment_record')) {
            Schema::create('payment_record', function (Blueprint $table) {
                $table->string('payment_id')->primary();
                $table->unsignedBigInteger('order_id');
                $table->string('payment_method')->nullable();
                $table->decimal('amount', 10, 2)->default(0.00);
                $table->string('transaction_id')->nullable();
                $table->string('payment_status')->default('pending');

                $table->string('gateway')->nullable();
                $table->string('status')->nullable();
                $table->timestamps();

                $table->foreign('order_id')->references('order_id')->on('order_header')->cascadeOnDelete();
            });
        }

        // 7. REVIEW
        if (!Schema::hasTable('review')) {
            Schema::create('review', function (Blueprint $table) {
                $table->id('review_id');
                $table->text('review_desc')->nullable();
                $table->unsignedBigInteger('product_id')->nullable();
                $table->unsignedBigInteger('reviewer_id')->nullable();
                $table->decimal('star_rating', 3, 2)->default(5.00);
                $table->unsignedBigInteger('reviewee_id')->nullable();

                $table->unsignedBigInteger('user_id')->nullable();
                $table->unsignedBigInteger('order_id')->nullable();
                $table->decimal('rating', 3, 2)->default(5.00);
                $table->text('comment')->nullable();
                $table->timestamps();

                $table->foreign('product_id')->references('product_id')->on('products')->cascadeOnDelete();
                $table->foreign('reviewer_id')->references('user_id')->on('users')->cascadeOnDelete();
                $table->foreign('reviewee_id')->references('user_id')->on('users')->nullOnDelete();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('review');
        Schema::dropIfExists('payment_record');
        Schema::dropIfExists('order_details');
        Schema::dropIfExists('order_header');
        Schema::dropIfExists('cart');
    }
};
