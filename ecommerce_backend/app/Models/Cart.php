<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Cart extends Model
{
    protected $table = 'carts';
    protected $primaryKey = 'id';

    protected $fillable = [
        'id',
        'user_id',
        'session_token',

        // Compatibility fields
        'cart_id',
        'product_id',
        'quantity',
    ];

    public function getIdAttribute()
    {
        return $this->attributes['id'] ?? $this->attributes['cart_id'] ?? null;
    }

    public function getCartIdAttribute()
    {
        return $this->attributes['id'] ?? $this->attributes['cart_id'] ?? null;
    }

    public function setCartIdAttribute($value)
    {
        $this->attributes['id'] = $value;
        $this->attributes['cart_id'] = $value;
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }

    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id', 'id');
    }

    public function items()
    {
        return $this->hasMany(CartItem::class, 'cart_id', 'id');
    }
}
