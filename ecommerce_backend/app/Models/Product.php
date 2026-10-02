<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    protected $table = 'products';
    protected $primaryKey = 'product_id';

    protected $fillable = [
        'id',
        'category_id',
        'name',
        'slug',
        'description',
        'base_price',
        'rating_avg',
        'total_reviews',
        'is_active',
        'is_featured',

        // Compatibility fields
        'product_id',
        'product_name',
        'product_img',
        'product_desc',
        'product_qty',
        'product_rating',
        'product_category',
        'product_price',
    ];

    public function getIdAttribute()
    {
        return $this->attributes['id'] ?? $this->attributes['product_id'] ?? null;
    }

    public function setIdAttribute($value)
    {
        $this->attributes['id'] = $value;
    }

    public function getProductIdAttribute()
    {
        return $this->attributes['id'] ?? $this->attributes['product_id'] ?? null;
    }

    public function setProductIdAttribute($value)
    {
        $this->attributes['id'] = $value;
    }

    public function getNameAttribute()
    {
        return $this->attributes['name'] ?? $this->attributes['product_name'] ?? null;
    }

    public function setNameAttribute($value)
    {
        $this->attributes['name'] = $value;
    }

    public function getProductNameAttribute()
    {
        return $this->attributes['name'] ?? $this->attributes['product_name'] ?? null;
    }

    public function setProductNameAttribute($value)
    {
        $this->attributes['name'] = $value;
    }

    public function getBasePriceAttribute()
    {
        return $this->attributes['base_price'] ?? $this->attributes['product_price'] ?? 0.00;
    }

    public function setBasePriceAttribute($value)
    {
        $this->attributes['base_price'] = $value;
    }

    public function getProductPriceAttribute()
    {
        return $this->attributes['base_price'] ?? $this->attributes['product_price'] ?? 0.00;
    }

    public function setProductPriceAttribute($value)
    {
        $this->attributes['base_price'] = $value;
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function variants()
    {
        return $this->hasMany(ProductVariant::class, 'product_id', 'id');
    }

    public function images()
    {
        return $this->hasMany(ProductImage::class, 'product_id', 'id');
    }

    public function reviews()
    {
        return $this->hasMany(Review::class, 'product_id', 'id');
    }
}
