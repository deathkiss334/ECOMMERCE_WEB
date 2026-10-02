<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    protected $table = 'orders';
    protected $primaryKey = 'id';

    protected $fillable = [
        'id',
        'order_number',
        'user_id',
        'user_address_id',
        'status',
        'payment_status',
        'subtotal',
        'delivery_fee',
        'discount_amount',
        'total_amount',
        'notes',
        'gcash_ref_number',
        'receipt_image_url',
        'admin_notes',
        'verified_at',

        // Compatibility fields
        'customer_name',
        'customer_email',
        'rejection_reason',
        'lalamove_tracking_url',
        'order_id',
        'customer_id',
        'payment_method',
        'total_paid',
        'order_type',
        'gcash_reference_no',
        'gcash_receipt_path',
        'gcash_ref_number',
        'receipt_image_url',
        'admin_notes',
        'verified_at',
    ];

    public function getIdAttribute()
    {
        return $this->attributes['id'] ?? $this->attributes['order_id'] ?? null;
    }

    public function setIdAttribute($value)
    {
        $this->attributes['id'] = $value;
    }

    public function getOrderIdAttribute()
    {
        return $this->attributes['id'] ?? $this->attributes['order_id'] ?? null;
    }

    public function setOrderIdAttribute($value)
    {
        $this->attributes['id'] = $value;
    }

    public function getUserIdAttribute()
    {
        return $this->attributes['user_id'] ?? $this->attributes['customer_id'] ?? null;
    }

    public function setUserIdAttribute($value)
    {
        $this->attributes['user_id'] = $value;
    }

    public function getCustomerIdAttribute()
    {
        return $this->attributes['user_id'] ?? $this->attributes['customer_id'] ?? null;
    }

    public function setCustomerIdAttribute($value)
    {
        $this->attributes['user_id'] = $value;
    }

    public function getTotalAmountAttribute()
    {
        return (float) ($this->attributes['total_amount'] ?? $this->attributes['total_paid'] ?? 0.00);
    }

    public function setTotalAmountAttribute($value)
    {
        $this->attributes['total_amount'] = $value;
    }

    public function getTotalPaidAttribute()
    {
        return (float) ($this->attributes['total_amount'] ?? $this->attributes['total_paid'] ?? 0.00);
    }

    public function setTotalPaidAttribute($value)
    {
        $this->attributes['total_amount'] = $value;
    }

    public function getGcashReferenceNoAttribute()
    {
        return $this->attributes['gcash_ref_number'] ?? $this->attributes['gcash_reference_no'] ?? null;
    }

    public function setGcashReferenceNoAttribute($value)
    {
        $this->attributes['gcash_ref_number'] = $value;
    }

    public function getGcashRefNumberAttribute()
    {
        return $this->attributes['gcash_ref_number'] ?? $this->attributes['gcash_reference_no'] ?? null;
    }

    public function setGcashRefNumberAttribute($value)
    {
        $this->attributes['gcash_ref_number'] = $value;
    }

    public function getGcashReceiptPathAttribute()
    {
        return $this->attributes['receipt_image_url'] ?? $this->attributes['gcash_receipt_path'] ?? null;
    }

    public function setGcashReceiptPathAttribute($value)
    {
        $this->attributes['receipt_image_url'] = $value;
    }

    public function getReceiptImageUrlAttribute()
    {
        return $this->attributes['receipt_image_url'] ?? $this->attributes['gcash_receipt_path'] ?? null;
    }

    public function setReceiptImageUrlAttribute($value)
    {
        $this->attributes['receipt_image_url'] = $value;
    }

    public function customer()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }

    public function orderDetails()
    {
        return $this->hasMany(OrderItem::class, 'order_id', 'id');
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class, 'order_id', 'id');
    }

    public function paymentRecord()
    {
        return $this->hasOne(Payment::class, 'order_id', 'id');
    }

    public function payments()
    {
        return $this->hasMany(Payment::class, 'order_id', 'id');
    }

    public function latestPayment()
    {
        return $this->hasOne(Payment::class, 'order_id', 'id')->latestOfMany('created_at');
    }

    public function chats()
    {
        return $this->hasMany(OrderChat::class, 'order_id', 'order_number');
    }

    public function review()
    {
        return $this->hasOne(OrderReview::class, 'order_id', 'order_number');
    }
}
