<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    protected $table = 'orders';
    protected $primaryKey = 'order_id';

    protected $fillable = [
        'order_id',
        'customer_id',
        'payment_method',
        'total_paid',
        'order_type',

        // Compatibility fields
        'order_number',
        'user_id',
        'status',
        'payment_status',
        'subtotal',
        'delivery_fee',
        'total_amount',
        'notes',
        'gcash_reference_no',
        'gcash_receipt_path',
        'gcash_ref_number',
        'receipt_image_url',
        'admin_notes',
        'verified_at',
    ];

    public function getIdAttribute()
    {
        return $this->attributes['order_id'] ?? $this->attributes['id'] ?? null;
    }

    public function getUserIdAttribute()
    {
        return $this->attributes['customer_id'] ?? $this->attributes['user_id'] ?? null;
    }

    public function setUserIdAttribute($value)
    {
        $this->attributes['customer_id'] = $value;
        $this->attributes['user_id'] = $value;
    }

    public function getTotalAmountAttribute()
    {
        return $this->attributes['total_paid'] ?? $this->attributes['total_amount'] ?? 0.00;
    }

    public function setTotalAmountAttribute($value)
    {
        $this->attributes['total_paid'] = $value;
        $this->attributes['total_amount'] = $value;
    }

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id', 'user_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'customer_id', 'user_id');
    }

    public function orderDetails()
    {
        return $this->hasMany(OrderItem::class, 'order_id', 'order_id');
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class, 'order_id', 'order_id');
    }

    public function paymentRecord()
    {
        return $this->hasOne(Payment::class, 'order_id', 'order_id');
    }

    public function payments()
    {
        return $this->hasMany(Payment::class, 'order_id', 'order_id');
    }

    public function latestPayment()
    {
        return $this->hasOne(Payment::class, 'order_id', 'order_id')->latestOfMany('created_at');
    }
}
