<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ProductTable extends Model
{
    use HasFactory;

    protected $table = 'product_table';
    protected $primaryKey = 'product_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'product_id',
        'product_quantity',
        'product_type',
        'product_description',
        'product_price',
        'product_image',
    ];

    protected $casts = [
        'product_quantity' => 'integer',
        'product_price'    => 'double',
    ];

    // Aliases for compatibility
    public function getIdAttribute()
    {
        return $this->attributes['product_id'] ?? null;
    }

    public function getNameAttribute()
    {
        return $this->attributes['product_type'] ?? null;
    }

    public function getPriceAttribute()
    {
        return (float) ($this->attributes['product_price'] ?? 0.0);
    }

    public function getBasePriceAttribute()
    {
        return (float) ($this->attributes['product_price'] ?? 0.0);
    }

    public function getImageAttribute()
    {
        return $this->attributes['product_image'] ?? '';
    }

    public function getDescriptionAttribute()
    {
        return $this->attributes['product_description'] ?? '';
    }
}
