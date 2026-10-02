<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderChat extends Model
{
    protected $table = 'order_chats';

    protected $fillable = [
        'order_id',
        'sender_role',
        'sender_name',
        'message',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id', 'order_number');
    }
}
