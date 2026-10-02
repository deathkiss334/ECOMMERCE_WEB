<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Models\Category;
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
use App\Http\Controllers\Api\OrderChatController;
use App\Http\Controllers\Api\OrderReviewController;

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
    Route::get('/users', [AdminController::class, 'users']);
    Route::put('/users/{id}/role', [AdminController::class, 'updateUserRole']);
});

// Admin verification and order management without sanctum requirement (for development & test panels)
Route::get('/admin/orders', [AdminController::class, 'orders']);
Route::patch('/admin/orders/{orderId}/verify', [AdminController::class, 'verifyOrder']);
Route::post('/admin/orders/{id}/verify-payment', [AdminController::class, 'verifyPayment']);
Route::get('/admin/orders-list', [AdminController::class, 'orders']);

// ── E-Commerce Catalog API Endpoints ──────────────────────────────────────────
Route::get('/categories', function () {
    return Category::whereRaw('is_active IS TRUE')->get();
});

Route::get('/products', [ProductTableController::class, 'catalog']);
Route::get('/products/featured', [ProductTableController::class, 'catalog']);
Route::get('/products/{slug}', [ProductTableController::class, 'catalogItem']);

// ── Checkout & GCash Payment Endpoints ───────────────────────────────────────
Route::post('/checkout', [CheckoutController::class, 'store']);
Route::post('/orders/create', [CheckoutController::class, 'store']);
Route::post('/orders/{orderId}/upload-receipt', [QrPaymentController::class, 'uploadReceipt']);
Route::get('/orders/{orderId}/status', [OrderHistoryController::class, 'orderStatus']);
Route::post('/payments/submit-reference', [QrPaymentController::class, 'submitReference']);
Route::post('/payments/qr-confirm', [QrPaymentController::class, 'confirm']);

// ── Customer Order History & Real-Time Tracking ───────────────────────────────
Route::get('/orders', [OrderHistoryController::class, 'index']);
Route::get('/orders/track/{order_number}', function ($order_number) {
    $order = \App\Services\OrderService::findOrder($order_number);
    if (!$order) {
        abort(404, 'Order not found');
    }
    return response()->json($order);
});
Route::post('/orders/reviews', [OrderHistoryController::class, 'storeReview']);

// ── Live Order Chat Endpoints (Customer <-> Admin) ──────────────────────────
Route::get('/orders/{orderId}/chat', [OrderChatController::class, 'index']);
Route::get('/orders/{orderId}/chats', [OrderChatController::class, 'index']);
Route::post('/orders/{orderId}/chat', [OrderChatController::class, 'store']);
Route::post('/orders/{orderId}/chats', [OrderChatController::class, 'store']);

// ── Lalamove Tracking Link Endpoints ────────────────────────────────────────
Route::patch('/orders/{orderId}/tracking', [AdminController::class, 'updateTrackingUrl']);
Route::patch('/admin/orders/{orderId}/tracking', [AdminController::class, 'updateTrackingUrl']);
Route::post('/orders/{orderId}/tracking', [AdminController::class, 'updateTrackingUrl']);
Route::post('/admin/orders/{orderId}/tracking', [AdminController::class, 'updateTrackingUrl']);

// ── Post-Order Rating & Feedback Endpoints ──────────────────────────────────
Route::get('/orders/{orderId}/review', [OrderReviewController::class, 'show']);
Route::post('/orders/{orderId}/review', [OrderReviewController::class, 'store']);

// ── Admin Order Management Direct Routes (Development & Mobile App) ─────────
Route::patch('/admin/orders/{orderId}/status', [AdminController::class, 'updateOrderStatus']);
Route::post('/admin/orders/{orderId}/status', [AdminController::class, 'updateOrderStatus']);

// ── Product Table API Endpoints ───────────────────────────────────────────────
Route::get('/product-table', [ProductTableController::class, 'index']);
Route::post('/product-table', [ProductTableController::class, 'store']);
Route::put('/product-table/{id}', [ProductTableController::class, 'update']);
Route::delete('/product-table/{id}', [ProductTableController::class, 'destroy']);

// ── Users Table API Endpoints ─────────────────────────────────────────────────
Route::get('/users-table', [UsersTableController::class, 'index']);
Route::post('/users-table', [UsersTableController::class, 'store']);
Route::delete('/users-table/{id}', [UsersTableController::class, 'destroy']);
