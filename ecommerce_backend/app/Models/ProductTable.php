<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ProductTable extends Model
{
    use HasFactory;

    protected $table = 'products';
    protected $primaryKey = 'product_id';
    public $incrementing = true;

    protected $fillable = [
        'product_id',
        'product_name',
        'product_img',
        'product_desc',
        'product_qty',
        'product_rating',
        'product_category',
        'product_price',
        'name',
        'base_price',
    ];

    protected $casts = [
        'product_qty' => 'integer',
        'product_price' => 'double',
        'product_rating' => 'double',
    ];

    public function getProductTypeAttribute()
    {
        return $this->attributes['product_name'] ?? $this->attributes['product_type'] ?? '';
    }

    public function setProductTypeAttribute($value)
    {
        $this->attributes['product_name'] = $value;
        $this->attributes['name'] = $value;
    }

    public function getProductQuantityAttribute()
    {
        return $this->attributes['product_qty'] ?? $this->attributes['product_quantity'] ?? 0;
    }

    public function setProductQuantityAttribute($value)
    {
        $this->attributes['product_qty'] = $value;
    }
}
