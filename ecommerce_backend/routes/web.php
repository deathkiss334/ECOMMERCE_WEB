<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\OrderController;

Route::get('/', function () {
    return view('welcome');
});

// Phase 4: Admin Dashboard Routes
Route::get('/admin/orders', [OrderController::class, 'index']);
Route::post('/admin/orders/{id}/status', [OrderController::class, 'updateStatus']);
