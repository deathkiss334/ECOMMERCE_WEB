<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\GoogleTokenVerifier;
use App\Services\SupabaseService;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Symfony\Component\HttpFoundation\Response;

class AuthController extends Controller
{
    /**
     * Dummy bcrypt hash used for constant-time comparison on failed user lookups.
     */
    protected const DUMMY_HASH = '$2y$12$e0MYzXyjpJS7Pd0RVvHwHeT94c9n2GfP4qHkM6pT5e5vXo3Z1K.2y';

    /**
     * Password policy regex:
     * - Minimum 8 characters
     * - At least 1 uppercase letter
     * - At least 1 lowercase letter
     * - At least 1 digit
     * - At least 1 special character
     */
    protected const PASSWORD_REGEX = '/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#^()_+=\-\[\]{}|:;<>,.~`])[A-Za-z\d@$!%*?&#^()_+=\-\[\]{}|:;<>,.~`]{8,}$/';

    public function __construct(
        protected GoogleTokenVerifier $googleVerifier
    ) {}

    /**
     * Sign Up / Local Registration
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function register(Request $request): JsonResponse
    {
        $rawEmail = strtolower(trim((string) $request->input('email', '')));
        $rawName = trim((string) $request->input('name', ''));
        $rawPhone = $request->filled('phone') ? trim((string) $request->input('phone')) : null;
        $password = (string) $request->input('password', '');

        // 1. Strict Input Validation
        $validator = Validator::make([
            'email' => $rawEmail,
            'name' => $rawName,
            'phone' => $rawPhone,
            'password' => $password,
        ], [
            'email' => ['required', 'string', 'email:rfc,filter', 'max:255'],
            'name' => ['required', 'string', 'min:2', 'max:100'],
            'phone' => ['nullable', 'string', 'max:25'],
            'password' => ['required', 'string', 'min:8', 'regex:' . self::PASSWORD_REGEX],
        ], [
            'password.regex' => 'Password must contain at least 1 uppercase letter, 1 lowercase letter, 1 number, and 1 special character.',
            'name.min' => 'Name must be at least 2 characters.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        // 2. Reject duplicate emails with explicit 409 Conflict
        $existingUser = User::where('email', $rawEmail)->first();
        if ($existingUser) {
            return response()->json([
                'message' => 'Email is already registered. Please log in instead.',
                'error' => 'CONFLICT',
            ], Response::HTTP_CONFLICT);
        }

        // 3. Create user in SQLite with hashed password
        $user = User::create([
            'name' => $rawName,
            'email' => $rawEmail,
            'password_hash' => Hash::make($password),
            'phone' => $rawPhone,
            'role' => 'customer',
            'auth_provider' => 'local',
            'google_id' => null,
        ]);

        // 4. Issue Sanctum Bearer Token
        $token = $user->createToken('auth-token', ['role:' . $user->role])->plainTextToken;

        // 5. Sync new user profile to Supabase
        SupabaseService::syncUser([
            'email'         => $user->email,
            'name'          => $user->name,
            'phone'         => $user->phone,
            'role'          => $user->role,
            'auth_provider' => $user->auth_provider,
            'google_id'     => null,
        ]);

        return response()->json([
            'message' => 'Registration successful.',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'phone' => $user->phone,
                'auth_provider' => $user->auth_provider,
            ],
        ], Response::HTTP_CREATED);
    }

    /**
     * Local Log In
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function login(Request $request): JsonResponse
    {
        $rawEmail = strtolower(trim((string) $request->input('email', '')));
        $password = (string) $request->input('password', '');

        if (empty($rawEmail) || empty($password)) {
            return response()->json([
                'message' => 'Invalid email or password.',
                'error' => 'UNAUTHORIZED',
            ], Response::HTTP_UNAUTHORIZED);
        }

        // Query user by email
        $user = User::where('email', $rawEmail)->first();

        // Constant-time verification protection
        if (!$user || empty($user->password_hash)) {
            // Run dummy hash check to defeat side-channel timing analysis
            Hash::check($password, self::DUMMY_HASH);

            return response()->json([
                'message' => 'Invalid email or password.',
                'error' => 'UNAUTHORIZED',
            ], Response::HTTP_UNAUTHORIZED);
        }

        // Verify password against stored hash
        if (!Hash::check($password, $user->password_hash)) {
            return response()->json([
                'message' => 'Invalid email or password.',
                'error' => 'UNAUTHORIZED',
            ], Response::HTTP_UNAUTHORIZED);
        }

        // Generate token
        $token = $user->createToken('auth-token', ['role:' . $user->role])->plainTextToken;

        return response()->json([
            'message' => 'Login successful.',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'phone' => $user->phone,
                'auth_provider' => $user->auth_provider,
            ],
        ], Response::HTTP_OK);
    }

    /**
     * Google OAuth 2.0 Sign In / Auto-Registration (Zero Firebase)
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function googleAuth(Request $request): JsonResponse
    {
        $idToken = $request->input('id_token') 
            ?? $request->input('idToken')
            ?? $request->input('credential') 
            ?? $request->input('token')
            ?? $request->input('google_token')
            ?? $request->input('google_id_token')
            ?? $request->bearerToken();

        if (empty($idToken)) {
            $rawJson = json_decode($request->getContent(), true);
            if (is_array($rawJson)) {
                $idToken = $rawJson['id_token'] ?? $rawJson['idToken'] ?? $rawJson['credential'] ?? $rawJson['token'] ?? null;
            }
        }

        if (empty($idToken) || !is_string($idToken)) {
            return response()->json([
                'message' => 'Google ID token is required. Please provide {"id_token": "<GOOGLE_ID_TOKEN>"} in your JSON request body.',
                'error' => 'BAD_REQUEST',
                'expected_body' => [
                    'id_token' => '<google_id_token_from_client>',
                ],
            ], Response::HTTP_BAD_REQUEST);
        }

        try {
            // Verify Google token cryptographically & against Google's OAuth2 endpoints
            $googleProfile = $this->googleVerifier->verify($idToken);
        } catch (Exception $e) {
            return response()->json([
                'message' => 'Google authentication failed: ' . $e->getMessage(),
                'error' => 'GOOGLE_AUTH_FAILED',
            ], Response::HTTP_UNAUTHORIZED);
        }

        $googleId = $googleProfile['google_id'];
        $email = strtolower(trim($googleProfile['email']));
        $googleName = trim($googleProfile['name'] ?? '');
        $nameParts = explode(' ', $googleName, 2);
        $firstName = $request->input('first_name') ?: ($nameParts[0] ?? $googleName);
        $lastName = $request->input('last_name') ?: ($nameParts[1] ?? '');

        // 1. Fetch user from Supabase users_table
        $existing = SupabaseService::getUserFromSupabase($email);

        $address = $request->input('address') ?: ($existing['address'] ?? '');
        $phoneNumber = $request->input('phone_number') ?: ($request->input('phone') ?: ($existing['phone_number'] ?? ''));
        $role = $existing['user_role'] ?? 'customer';
        $userId = $existing['user_id'] ?? (string) \Illuminate\Support\Str::uuid();

        // 2. Save / update profile in Supabase users_table
        $userData = [
            'email_address' => $email,
            'first_name'    => !empty($existing['first_name']) ? $existing['first_name'] : $firstName,
            'last_name'     => !empty($existing['last_name']) ? $existing['last_name'] : $lastName,
            'address'       => $address,
            'phone_number'  => $phoneNumber,
            'user_role'     => $role,
            'user_id'       => $userId,
        ];

        SupabaseService::saveUserToSupabase($userData);

        // Generate synthetic sanctum-compatible bearer token
        $token = base64_encode(json_encode([
            'email' => $email,
            'role'  => $role,
            'exp'   => time() + 86400 * 30,
        ]));

        $needsCredentials = empty($address) || empty($phoneNumber);

        return response()->json([
            'message' => 'Google authentication successful.',
            'token'   => $token,
            'user'    => [
                'id'                       => $userId,
                'user_id'                  => $userId,
                'name'                     => trim(($userData['first_name'] ?? '') . ' ' . ($userData['last_name'] ?? '')),
                'first_name'               => $userData['first_name'],
                'last_name'                => $userData['last_name'],
                'email'                    => $email,
                'email_address'            => $email,
                'role'                     => $role,
                'phone'                    => $phoneNumber,
                'phone_number'             => $phoneNumber,
                'address'                  => $address,
                'auth_provider'            => 'google',
                'needs_profile_completion' => $needsCredentials,
            ],
        ], Response::HTTP_OK);
    }

    /**
     * Log Out / Revoke Current Access Token
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user && $user->currentAccessToken()) {
            $user->currentAccessToken()->delete();
        }

        return response()->json([
            'message' => 'Logged out successfully.',
        ], Response::HTTP_OK);
    }
}
