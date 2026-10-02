<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthAndUserManagementTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test user registration with strict validation and successful 201 response.
     */
    public function test_user_registration_success(): void
    {
        $payload = [
            'name' => 'Alice Test',
            'email' => 'alice@example.com',
            'phone' => '09123456780',
            'password' => 'StrongP@ss123',
        ];

        $response = $this->postJson('/api/auth/register', $payload);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'message',
                'token',
                'user' => ['id', 'name', 'email', 'role', 'phone', 'auth_provider'],
            ])
            ->assertJsonMissing(['password_hash'])
            ->assertJson([
                'user' => [
                    'name' => 'Alice Test',
                    'email' => 'alice@example.com',
                    'role' => 'customer',
                    'auth_provider' => 'local',
                ],
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'alice@example.com',
            'role' => 'customer',
            'auth_provider' => 'local',
        ]);
    }

    /**
     * Test duplicate email registration returns explicit 409 Conflict.
     */
    public function test_user_registration_duplicate_email_returns_409(): void
    {
        User::create([
            'name' => 'Existing User',
            'email' => 'duplicate@example.com',
            'password_hash' => Hash::make('StrongP@ss123'),
            'role' => 'customer',
            'auth_provider' => 'local',
        ]);

        $response = $this->postJson('/api/auth/register', [
            'name' => 'New Guy',
            'email' => 'duplicate@example.com',
            'password' => 'StrongP@ss123',
        ]);

        $response->assertStatus(409)
            ->assertJson([
                'error' => 'CONFLICT',
            ]);
    }

    /**
     * Test password policy rejects weak passwords.
     */
    public function test_user_registration_rejects_weak_passwords(): void
    {
        // Missing special character and uppercase
        $response = $this->postJson('/api/auth/register', [
            'name' => 'Weak Password Guy',
            'email' => 'weak@example.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }

    /**
     * Test login with valid credentials.
     */
    public function test_user_login_success(): void
    {
        $user = User::create([
            'name' => 'Bob Tester',
            'email' => 'bob@example.com',
            'password_hash' => Hash::make('SecurePassword!123'),
            'role' => 'customer',
            'auth_provider' => 'local',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'bob@example.com',
            'password' => 'SecurePassword!123',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'token',
                'user' => ['id', 'name', 'email', 'role'],
            ])
            ->assertJsonMissing(['password_hash']);
    }

    /**
     * Test login with invalid password returns generic 401.
     */
    public function test_user_login_invalid_password_returns_401(): void
    {
        User::create([
            'name' => 'Bob Tester',
            'email' => 'bob_fail@example.com',
            'password_hash' => Hash::make('SecurePassword!123'),
            'role' => 'customer',
            'auth_provider' => 'local',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'bob_fail@example.com',
            'password' => 'WrongPassword!999',
        ]);

        $response->assertStatus(401)
            ->assertJson(['message' => 'Invalid email or password.']);
    }

    /**
     * Test non-existent user login returns generic 401.
     */
    public function test_user_login_non_existent_returns_401(): void
    {
        $response = $this->postJson('/api/auth/login', [
            'email' => 'nonexistent@example.com',
            'password' => 'SecurePassword!123',
        ]);

        $response->assertStatus(401)
            ->assertJson(['message' => 'Invalid email or password.']);
    }

    /**
     * Test customer cannot access admin endpoints (immediate 403 Forbidden).
     */
    public function test_customer_cannot_access_admin_endpoints(): void
    {
        $customer = User::create([
            'name' => 'Regular Customer',
            'email' => 'customer_guard@example.com',
            'password_hash' => Hash::make('SecurePass!123'),
            'role' => 'customer',
            'auth_provider' => 'local',
        ]);

        $token = $customer->createToken('test-token', ['role:customer'])->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/admin/orders');

        $response->assertStatus(403)
            ->assertJson([
                'error' => 'FORBIDDEN',
            ]);
    }

    /**
     * Test admin can access admin endpoints.
     */
    public function test_admin_can_access_admin_endpoints(): void
    {
        $admin = User::create([
            'name' => 'System Admin',
            'email' => 'admin_guard@example.com',
            'password_hash' => Hash::make('SecureAdminPass!123'),
            'role' => 'admin',
            'auth_provider' => 'local',
        ]);

        $token = $admin->createToken('admin-token', ['role:admin'])->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/admin/orders');

        $response->assertStatus(200);
    }

    /**
     * Test user profile retrieval and update.
     */
    public function test_user_profile_crud(): void
    {
        $user = User::create([
            'name' => 'Initial Name',
            'email' => 'profile_test@example.com',
            'password_hash' => Hash::make('SecurePass!123'),
            'phone' => '09111111111',
            'role' => 'customer',
            'auth_provider' => 'local',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        // 1. GET profile
        $getResponse = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/user/profile');

        $getResponse->assertStatus(200)
            ->assertJson([
                'user' => [
                    'name' => 'Initial Name',
                    'email' => 'profile_test@example.com',
                    'phone' => '09111111111',
                ],
            ]);

        // 2. PUT profile
        $updateResponse = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->putJson('/api/user/profile', [
                'name' => 'Updated Name',
                'phone' => '09222222222',
            ]);

        $updateResponse->assertStatus(200)
            ->assertJson([
                'user' => [
                    'name' => 'Updated Name',
                    'phone' => '09222222222',
                ],
            ]);

        $this->assertDatabaseHas('users', [
            'user_id' => $user->id,
            'name' => 'Updated Name',
            'phone' => '09222222222',
        ]);
    }

    /**
     * Test change password for local user.
     */
    public function test_change_password_success(): void
    {
        $user = User::create([
            'name' => 'Password Changer',
            'email' => 'pwd_change@example.com',
            'password_hash' => Hash::make('OldPassword!123'),
            'role' => 'customer',
            'auth_provider' => 'local',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->putJson('/api/user/change-password', [
                'current_password' => 'OldPassword!123',
                'new_password' => 'NewPassword!456',
                'confirm_new_password' => 'NewPassword!456',
            ]);

        $response->assertStatus(200);

        // Verify new password works
        $user->refresh();
        $this->assertTrue(Hash::check('NewPassword!456', $user->password_hash));
    }

    /**
     * Test change password blocked for Google OAuth users.
     */
    public function test_change_password_blocked_for_google_oauth_accounts(): void
    {
        $googleUser = User::create([
            'name' => 'Google Person',
            'email' => 'google_pwd@example.com',
            'password_hash' => null,
            'role' => 'customer',
            'auth_provider' => 'google',
            'google_id' => 'google-999-xyz',
        ]);

        $token = $googleUser->createToken('google-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->putJson('/api/user/change-password', [
                'current_password' => 'Whatever',
                'new_password' => 'NewPassword!456',
                'confirm_new_password' => 'NewPassword!456',
            ]);

        $response->assertStatus(400)
            ->assertJson([
                'error' => 'FORBIDDEN_PROVIDER',
            ]);
    }

    /**
     * Test Google OAuth auto-registration for new user.
     */
    public function test_google_oauth_auto_registers_new_user(): void
    {
        $verifierMock = $this->mock(\App\Services\GoogleTokenVerifier::class);
        $verifierMock->shouldReceive('verify')->with('mock_new_google_token')->andReturn([
            'google_id' => 'google_sub_12345',
            'email' => 'google_new@example.com',
            'name' => 'Google Newbie',
            'avatar' => 'https://example.com/avatar.jpg',
            'email_verified' => true,
        ]);

        $response = $this->postJson('/api/auth/google', [
            'id_token' => 'mock_new_google_token',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'message' => 'Google registration successful.',
                'user' => [
                    'email' => 'google_new@example.com',
                    'name' => 'Google Newbie',
                    'role' => 'customer',
                    'auth_provider' => 'google',
                ],
            ])
            ->assertJsonMissing(['password_hash']);

        $this->assertDatabaseHas('users', [
            'email' => 'google_new@example.com',
            'google_id' => 'google_sub_12345',
            'auth_provider' => 'google',
            'role' => 'customer',
            'password_hash' => null,
        ]);
    }

    /**
     * Test Google OAuth login for existing user.
     */
    public function test_google_oauth_logs_in_existing_user(): void
    {
        User::create([
            'name' => 'Existing Google Guy',
            'email' => 'google_exists@example.com',
            'password_hash' => null,
            'role' => 'customer',
            'auth_provider' => 'google',
            'google_id' => 'google_sub_exists_999',
        ]);

        $verifierMock = $this->mock(\App\Services\GoogleTokenVerifier::class);
        $verifierMock->shouldReceive('verify')->with('mock_existing_google_token')->andReturn([
            'google_id' => 'google_sub_exists_999',
            'email' => 'google_exists@example.com',
            'name' => 'Existing Google Guy',
            'avatar' => null,
            'email_verified' => true,
        ]);

        $response = $this->postJson('/api/auth/google', [
            'id_token' => 'mock_existing_google_token',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'message' => 'Google login successful.',
                'user' => [
                    'email' => 'google_exists@example.com',
                    'role' => 'customer',
                ],
            ]);
    }
}

