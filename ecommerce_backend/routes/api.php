<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Models\Category;
use App\Models\Product;
use App\Models\Order;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// E-Commerce Catalog API endpoints
Route::get('/categories', function () {
    return Category::where('is_active', true)->get();
});

Route::get('/products', function () {
    return Product::with(['category', 'variants', 'images'])
        ->where('is_active', true)
        ->get();
});

Route::get('/products/featured', function () {
    return Product::with(['category', 'variants', 'images'])
        ->where('is_active', true)
        ->where('is_featured', true)
        ->get();
});

Route::get('/products/{slug}', function ($slug) {
    return Product::with(['category', 'variants', 'images'])
        ->where('slug', $slug)
        ->firstOrFail();
});

// Phase 3: Checkout & Payment Gateway Endpoints
Route::post('/checkout', [\App\Http\Controllers\Api\CheckoutController::class, 'store']);
Route::post('/webhooks/paymongo', [\App\Http\Controllers\Api\WebhookController::class, 'handlePaymongo']);

// Phase 4: Customer Order History & Real-Time Tracking
Route::get('/orders', function () {
    return Order::with(['items', 'latestPayment'])
        ->latest()
        ->get();
});

Route::get('/orders/track/{order_number}', function ($order_number) {
    return Order::with(['items', 'latestPayment'])
        ->where('order_number', $order_number)
        ->firstOrFail();
});
Route::get('/orders', [\App\Http\Controllers\Api\OrderHistoryController::class, 'index']);
Route::post('/orders/reviews', [\App\Http\Controllers\Api\OrderHistoryController::class, 'storeReview']);
