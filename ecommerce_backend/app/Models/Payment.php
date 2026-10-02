<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Payment extends Model
{
    protected $table = 'payments';
    protected $primaryKey = 'payment_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'payment_id',
        'id',
        'order_id',
        'payment_method',
        'gateway',
        'gateway_reference_id',
        'amount',
        'currency',
        'status',
        'metadata',
        'transaction_id',
        'payment_status',
    ];

    protected static function booted()
    {
        static::creating(function ($payment) {
            if (empty($payment->payment_id) && empty($payment->id)) {
                $payment->payment_id = (string) Str::uuid();
            }
        });
    }

    public function getIdAttribute()
    {
        return $this->attributes['payment_id'] ?? $this->attributes['id'] ?? null;
    }

    public function setIdAttribute($value)
    {
        $this->attributes['payment_id'] = $value;
        $this->attributes['id'] = $value;
    }

    public function getPaymentIdAttribute()
    {
        return $this->attributes['payment_id'] ?? $this->attributes['id'] ?? null;
    }

    public function setPaymentIdAttribute($value)
    {
        $this->attributes['payment_id'] = $value;
    }

    public function getStatusAttribute()
    {
        return $this->attributes['status'] ?? $this->attributes['payment_status'] ?? 'pending';
    }

    public function setStatusAttribute($value)
    {
        $this->attributes['status'] = $value;
    }

    public function getPaymentStatusAttribute()
    {
        return $this->attributes['status'] ?? $this->attributes['payment_status'] ?? 'pending';
    }

    public function setPaymentStatusAttribute($value)
    {
        $this->attributes['status'] = $value;
    }

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id', 'order_id');
    }

    public function transactions()
    {
        return $this->hasMany(PaymentTransaction::class, 'payment_id', 'payment_id');
    }
}
