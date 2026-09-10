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
        'product_price',
    ];

    protected $casts = [
        'product_quantity' => 'integer',
        'product_price' => 'double',
    ];
}
