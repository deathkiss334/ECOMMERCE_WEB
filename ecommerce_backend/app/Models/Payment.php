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
        'order_id',
        'payment_method',
        'amount',
        'transaction_id',
        'payment_status',

        // Compatibility fields
        'gateway',
        'status',
    ];

    protected static function booted()
    {
        static::creating(function ($payment) {
            if (empty($payment->payment_id)) {
                $payment->payment_id = (string) Str::uuid();
            }
        });
    }

    public function getIdAttribute()
    {
        return $this->attributes['payment_id'] ?? null;
    }

    public function setIdAttribute($value)
    {
        $this->attributes['payment_id'] = $value;
    }

    public function getStatusAttribute()
    {
        return $this->attributes['payment_status'] ?? $this->attributes['status'] ?? 'pending';
    }

    public function setStatusAttribute($value)
    {
        $this->attributes['payment_status'] = $value;
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
