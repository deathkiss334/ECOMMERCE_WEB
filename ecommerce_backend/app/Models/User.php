<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected $table = 'users';
    protected $primaryKey = 'user_id';

    protected $fillable = [
        'id',
        'name',
        'email',
        'password_hash',
        'phone',
        'role',
        'auth_provider',
        'google_id',

        // Compatibility fields
        'user_id',
        'first_name',
        'last_name',
        'birthday',
        'address',
        'phone_num',
        'email_address',
        'password',
    ];

    protected $hidden = [
        'password',
        'password_hash',
        'remember_token',
    ];

    public function getAuthPasswordName(): string
    {
        return $this->password_hash ? 'password_hash' : 'password';
    }

    public function getAuthPassword()
    {
        return $this->password_hash ?? $this->password;
    }

    // Accessors & Mutators for ERD vs standard Laravel field compatibility
    public function getIdAttribute()
    {
        return $this->attributes['id'] ?? $this->attributes['user_id'] ?? null;
    }

    public function setIdAttribute($value)
    {
        $this->attributes['id'] = $value;
        $this->attributes['user_id'] = $value;
    }

    public function getUserIdAttribute()
    {
        return $this->attributes['id'] ?? $this->attributes['user_id'] ?? null;
    }

    public function setUserIdAttribute($value)
    {
        $this->attributes['id'] = $value;
        $this->attributes['user_id'] = $value;
    }

    public function getEmailAttribute()
    {
        return $this->attributes['email'] ?? $this->attributes['email_address'] ?? null;
    }

    public function setEmailAttribute($value)
    {
        $this->attributes['email_address'] = $value;
        $this->attributes['email'] = $value;
    }

    public function getPhoneAttribute()
    {
        return $this->attributes['phone_num'] ?? $this->attributes['phone'] ?? null;
    }

    public function setPhoneAttribute($value)
    {
        $this->attributes['phone_num'] = $value;
        $this->attributes['phone'] = $value;
    }

    public function getNameAttribute()
    {
        if (!empty($this->attributes['name'])) {
            return $this->attributes['name'];
        }
        return trim(($this->attributes['first_name'] ?? '') . ' ' . ($this->attributes['last_name'] ?? ''));
    }

    public function setNameAttribute($value)
    {
        $this->attributes['name'] = $value;
        $parts = explode(' ', $value, 2);
        $this->attributes['first_name'] = $parts[0] ?? '';
        $this->attributes['last_name'] = $parts[1] ?? '';
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function isCustomer(): bool
    {
        return $this->role === 'customer';
    }

    public function toProfileArray(): array
    {
        return [
            'user_id' => $this->user_id,
            'id' => $this->user_id,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'name' => $this->name,
            'birthday' => $this->birthday,
            'address' => $this->address,
            'phone_num' => $this->phone_num,
            'email_address' => $this->email_address,
            'email' => $this->email_address,
            'role' => $this->role,
            'auth_provider' => $this->auth_provider,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }
}
