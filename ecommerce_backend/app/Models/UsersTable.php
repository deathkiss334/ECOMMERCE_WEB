<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UsersTable extends Model
{
    use HasFactory;

    protected $table = 'users_table';
    protected $primaryKey = 'email_address';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'first_name',
        'middle_name',
        'last_name',
        'birthday',
        'address',
        'email_address',
        'phone_number',
    ];
}
