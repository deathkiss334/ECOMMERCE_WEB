<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Models\Category;
use App\Models\Product;
use App\Models\Order;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\QrPaymentController;
use App\Http\Controllers\Api\CheckoutController;
use App\Http\Controllers\Api\OrderHistoryController;
use App\Http\Controllers\Api\WebhookController;
use App\Http\Controllers\Api\ProductTableController;
use App\Http\Controllers\Api\UsersTableController;

// ── Authentication Endpoints (Public) ─────────────────────────────────────────
Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/signup', [AuthController::class, 'register']); // Alias for register
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/google', [AuthController::class, 'googleAuth']);
    Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');
});

// ── Profile & Credential Management (Requires auth:sanctum) ───────────────────
Route::middleware('auth:sanctum')->prefix('user')->group(function () {
    Route::get('/profile', [UserController::class, 'profile']);
    Route::put('/profile', [UserController::class, 'updateProfile']);
    Route::put('/change-password', [UserController::class, 'changePassword']);
});

// Legacy sanctum user route
Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// ── RBAC Protected Admin Endpoints (Requires auth:sanctum + role:admin) ───────
Route::middleware(['auth:sanctum', 'role:admin'])->prefix('admin')->group(function () {
    Route::get('/orders', [AdminController::class, 'orders']);
    Route::post('/orders/{id}/status', [AdminController::class, 'updateOrderStatus']);
    Route::post('/orders/{id}/verify-payment', [AdminController::class, 'verifyPayment']);
    Route::patch('/orders/{orderId}/verify', [AdminController::class, 'verifyOrder']);
    Route::get('/users', [AdminController::class, 'users']);
    Route::put('/users/{id}/role', [AdminController::class, 'updateUserRole']);
});

// Admin verification without sanctum requirement (for development & test panels)
Route::patch('/admin/orders/{orderId}/verify', [AdminController::class, 'verifyOrder']);
Route::get('/admin/orders-list', [AdminController::class, 'orders']);

// ── E-Commerce Catalog API Endpoints ──────────────────────────────────────────
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

// ── Checkout & GCash Payment Endpoints ───────────────────────────────────────
Route::post('/checkout', [CheckoutController::class, 'store']);
Route::post('/orders/create', [CheckoutController::class, 'store']);
Route::post('/orders/{orderId}/upload-receipt', [QrPaymentController::class, 'uploadReceipt']);
Route::get('/orders/{orderId}/status', [OrderHistoryController::class, 'orderStatus']);
Route::post('/payments/submit-reference', [QrPaymentController::class, 'submitReference']);
Route::post('/payments/qr-confirm', [QrPaymentController::class, 'confirm']);
Route::post('/webhooks/paymongo', [WebhookController::class, 'handlePaymongo']);

// ── Customer Order History & Real-Time Tracking ───────────────────────────────
Route::get('/orders', [OrderHistoryController::class, 'index']);
Route::get('/orders/track/{order_number}', function ($order_number) {
    return Order::with(['items', 'latestPayment'])
        ->where('order_number', $order_number)
        ->orWhere('id', $order_number)
        ->firstOrFail();
});
Route::post('/orders/reviews', [OrderHistoryController::class, 'storeReview']);

// ── Product Table API Endpoints ───────────────────────────────────────────────
Route::get('/product-table', [ProductTableController::class, 'index']);
Route::post('/product-table', [ProductTableController::class, 'store']);
Route::put('/product-table/{id}', [ProductTableController::class, 'update']);
Route::delete('/product-table/{id}', [ProductTableController::class, 'destroy']);

// ── Users Table API Endpoints ─────────────────────────────────────────────────
Route::get('/users-table', [UsersTableController::class, 'index']);
Route::post('/users-table', [UsersTableController::class, 'store']);
Route::delete('/users-table/{id}', [UsersTableController::class, 'destroy']);
