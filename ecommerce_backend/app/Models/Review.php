<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Review extends Model
{
    protected $table = 'reviews';
    protected $primaryKey = 'review_id';

    protected $fillable = [
        'id',
        'user_id',
        'product_id',
        'rating',
        'comment',

        // Compatibility fields
        'review_id',
        'review_desc',
        'reviewer_id',
        'star_rating',
        'reviewee_id',
        'order_id',
    ];

    public function getIdAttribute()
    {
        return $this->attributes['review_id'] ?? null;
    }

    public function setIdAttribute($value)
    {
        $this->attributes['review_id'] = $value;
    }

    public function getReviewIdAttribute()
    {
        return $this->attributes['review_id'] ?? null;
    }

    public function setReviewIdAttribute($value)
    {
        $this->attributes['review_id'] = $value;
    }

    public function getUserIdAttribute()
    {
        return $this->attributes['user_id'] ?? $this->attributes['reviewer_id'] ?? null;
    }

    public function setUserIdAttribute($value)
    {
        $this->attributes['user_id'] = $value;
        $this->attributes['reviewer_id'] = $value;
    }

    public function getReviewerIdAttribute()
    {
        return $this->attributes['user_id'] ?? $this->attributes['reviewer_id'] ?? null;
    }

    public function setReviewerIdAttribute($value)
    {
        $this->attributes['user_id'] = $value;
        $this->attributes['reviewer_id'] = $value;
    }

    public function getRatingAttribute()
    {
        return (float) ($this->attributes['rating'] ?? $this->attributes['star_rating'] ?? 5.00);
    }

    public function setRatingAttribute($value)
    {
        $this->attributes['rating'] = $value;
        $this->attributes['star_rating'] = $value;
    }

    public function getStarRatingAttribute()
    {
        return (float) ($this->attributes['rating'] ?? $this->attributes['star_rating'] ?? 5.00);
    }

    public function setStarRatingAttribute($value)
    {
        $this->attributes['rating'] = $value;
        $this->attributes['star_rating'] = $value;
    }

    public function getCommentAttribute()
    {
        return $this->attributes['comment'] ?? $this->attributes['review_desc'] ?? null;
    }

    public function setCommentAttribute($value)
    {
        $this->attributes['comment'] = $value;
        $this->attributes['review_desc'] = $value;
    }

    public function getReviewDescAttribute()
    {
        return $this->attributes['comment'] ?? $this->attributes['review_desc'] ?? null;
    }

    public function setReviewDescAttribute($value)
    {
        $this->attributes['comment'] = $value;
        $this->attributes['review_desc'] = $value;
    }

    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id', 'product_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }

    public function reviewee()
    {
        return $this->belongsTo(User::class, 'reviewee_id', 'user_id');
    }
}
