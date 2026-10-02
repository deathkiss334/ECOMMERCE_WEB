<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UsersTable extends Model
{
    use HasFactory;

    protected $table = 'users';
    protected $primaryKey = 'user_id';
    public $incrementing = true;

    protected $fillable = [
        'user_id',
        'first_name',
        'middle_name',
        'last_name',
        'birthday',
        'address',
        'phone_num',
        'email_address',
        'password',
    ];

    public function getPhoneNumberAttribute()
    {
        return $this->attributes['phone_num'] ?? $this->attributes['phone_number'] ?? '';
    }

    public function setPhoneNumberAttribute($value)
    {
        $this->attributes['phone_num'] = $value;
        $this->attributes['phone'] = $value;
    }
}
