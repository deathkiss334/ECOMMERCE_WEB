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
        Schema::create('reviews', function (Blueprint $table) {
            $table->id('review_id');
            $table->text('review_desc')->nullable();
            $table->foreignId('product_id')->constrained('products', 'product_id')->cascadeOnDelete();
            $table->foreignId('reviewer_id')->nullable()->constrained('users', 'user_id')->cascadeOnDelete();
            $table->decimal('star_rating', 3, 2)->default(5.00);
            $table->foreignId('reviewee_id')->nullable()->constrained('users', 'user_id')->nullOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users', 'user_id')->cascadeOnDelete();
            $table->foreignId('order_id')->nullable()->constrained('orders', 'order_id')->nullOnDelete();
            $table->decimal('rating', 3, 2)->default(5.00);
            $table->text('comment')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('reviews');
    }
};
