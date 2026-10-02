<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Review extends Model
{
    protected $table = 'review';
    protected $primaryKey = 'review_id';

    protected $fillable = [
        'review_id',
        'review_desc',
        'product_id',
        'reviewer_id',
        'star_rating',
        'reviewee_id',

        // Compatibility fields
        'user_id',
        'order_id',
        'rating',
        'comment',
    ];

    public function getReviewerIdAttribute()
    {
        return $this->attributes['reviewer_id'] ?? $this->attributes['user_id'] ?? null;
    }

    public function setReviewerIdAttribute($value)
    {
        $this->attributes['reviewer_id'] = $value;
        $this->attributes['user_id'] = $value;
    }

    public function getStarRatingAttribute()
    {
        return $this->attributes['star_rating'] ?? $this->attributes['rating'] ?? 5.00;
    }

    public function setStarRatingAttribute($value)
    {
        $this->attributes['star_rating'] = $value;
        $this->attributes['rating'] = $value;
    }

    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id', 'product_id');
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewer_id', 'user_id');
    }

    public function reviewee()
    {
        return $this->belongsTo(User::class, 'reviewee_id', 'user_id');
    }
}
