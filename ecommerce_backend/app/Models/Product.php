<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    protected $table = 'products';
    protected $primaryKey = 'product_id';

    protected $fillable = [
        'product_id',
        'product_name',
        'product_img',
        'product_desc',
        'product_qty',
        'product_rating',
        'product_category',
        'product_price',

        // Compatibility fields
        'category_id',
        'name',
        'slug',
        'description',
        'base_price',
        'rating_avg',
        'total_reviews',
        'is_active',
        'is_featured',
    ];

    public function getIdAttribute()
    {
        return $this->attributes['product_id'] ?? $this->attributes['id'] ?? null;
    }

    public function getNameAttribute()
    {
        return $this->attributes['product_name'] ?? $this->attributes['name'] ?? null;
    }

    public function setNameAttribute($value)
    {
        $this->attributes['product_name'] = $value;
        $this->attributes['name'] = $value;
    }

    public function getBasePriceAttribute()
    {
        return $this->attributes['product_price'] ?? $this->attributes['base_price'] ?? 0.00;
    }

    public function setBasePriceAttribute($value)
    {
        $this->attributes['product_price'] = $value;
        $this->attributes['base_price'] = $value;
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function variants()
    {
        return $this->hasMany(ProductVariant::class, 'product_id', 'product_id');
    }

    public function images()
    {
        return $this->hasMany(ProductImage::class, 'product_id', 'product_id');
    }

    public function reviews()
    {
        return $this->hasMany(Review::class, 'product_id', 'product_id');
    }
}
