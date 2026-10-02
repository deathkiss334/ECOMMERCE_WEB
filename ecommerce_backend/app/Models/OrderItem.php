<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    protected $table = 'order_items';
    protected $primaryKey = 'od_id';

    protected $fillable = [
        'id',
        'order_id',
        'product_variant_id',
        'product_name_snapshot',
        'variant_name_snapshot',
        'unit_price',
        'quantity',
        'total_price',
        'special_instructions',

        // Compatibility fields
        'od_id',
        'product_id',
        'product_name',
        'subtotal',
    ];

    public function getIdAttribute()
    {
        return $this->attributes['od_id'] ?? null;
    }

    public function setIdAttribute($value)
    {
        $this->attributes['od_id'] = $value;
    }

    public function getOdIdAttribute()
    {
        return $this->attributes['od_id'] ?? null;
    }

    public function setOdIdAttribute($value)
    {
        $this->attributes['od_id'] = $value;
    }

    public function getTotalPriceAttribute()
    {
        return (float) ($this->attributes['total_price'] ?? $this->attributes['subtotal'] ?? 0.00);
    }

    public function setTotalPriceAttribute($value)
    {
        $this->attributes['total_price'] = $value;
    }

    public function getSubtotalAttribute()
    {
        return (float) ($this->attributes['total_price'] ?? $this->attributes['subtotal'] ?? 0.00);
    }

    public function setSubtotalAttribute($value)
    {
        $this->attributes['total_price'] = $value;
    }

    public function getProductNameSnapshotAttribute()
    {
        return $this->attributes['product_name_snapshot'] ?? $this->attributes['product_name'] ?? '';
    }

    public function setProductNameSnapshotAttribute($value)
    {
        $this->attributes['product_name_snapshot'] = $value;
    }

    public function getProductNameAttribute()
    {
        return $this->attributes['product_name_snapshot'] ?? $this->attributes['product_name'] ?? '';
    }

    public function setProductNameAttribute($value)
    {
        $this->attributes['product_name_snapshot'] = $value;
    }

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id', 'order_id');
    }

    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id', 'product_id');
    }

    public function productVariant()
    {
        return $this->belongsTo(ProductVariant::class, 'product_variant_id', 'id');
    }
}
