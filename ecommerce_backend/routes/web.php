<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\OrderController;

Route::get('/', function () {
    return redirect('/admin/orders');
});

// Phase 4: Admin Dashboard Routes
Route::redirect('/admin', '/admin/orders');
Route::get('/admin/orders', [OrderController::class, 'index']);
Route::post('/admin/orders/{id}/status', [OrderController::class, 'updateStatus']);
