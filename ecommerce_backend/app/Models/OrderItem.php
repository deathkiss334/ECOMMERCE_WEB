<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    protected $table = 'order_details';
    protected $primaryKey = 'od_id';

    protected $fillable = [
        'od_id',
        'order_id',
        'product_id',
        'product_name',
        'quantity',
        'unit_price',
        'subtotal',

        // Compatibility fields
        'product_variant_id',
        'product_name_snapshot',
        'variant_name_snapshot',
        'total_price',
    ];

    public function getIdAttribute()
    {
        return $this->attributes['od_id'] ?? $this->attributes['id'] ?? null;
    }

    public function getTotalPriceAttribute()
    {
        return $this->attributes['subtotal'] ?? $this->attributes['total_price'] ?? 0.00;
    }

    public function setTotalPriceAttribute($value)
    {
        $this->attributes['subtotal'] = $value;
        $this->attributes['total_price'] = $value;
    }

    public function getProductNameSnapshotAttribute()
    {
        return $this->attributes['product_name'] ?? $this->attributes['product_name_snapshot'] ?? '';
    }

    public function setProductNameSnapshotAttribute($value)
    {
        $this->attributes['product_name'] = $value;
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
