<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderReview extends Model
{
    protected $table = 'order_reviews';

    protected $fillable = [
        'order_id',
        'user_id',
        'rating',
        'feedback',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id', 'order_number');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }
}
