<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Payment extends Model
{
    protected $table = 'payments';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'order_id',
        'payment_method',
        'gateway',
        'gateway_reference_id',
        'amount',
        'currency',
        'status',
        'metadata',
    ];

    protected static function booted()
    {
        static::creating(function ($payment) {
            if (empty($payment->id)) {
                $payment->id = (string) Str::uuid();
            }
        });
    }

    public function getIdAttribute()
    {
        return $this->attributes['id'] ?? null;
    }

    public function setIdAttribute($value)
    {
        $this->attributes['id'] = $value;
    }

    public function getPaymentIdAttribute()
    {
        return $this->attributes['id'] ?? null;
    }

    public function setPaymentIdAttribute($value)
    {
        $this->attributes['id'] = $value;
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
        return $this->belongsTo(Order::class, 'order_id', 'id');
    }

    public function transactions()
    {
        return $this->hasMany(PaymentTransaction::class, 'payment_id', 'id');
    }
}
