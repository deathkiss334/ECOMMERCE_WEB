<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\GoogleTokenVerifier;
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
        $email = $googleProfile['email'];
        $name = $googleProfile['name'];

        // Match Flow:
        // 1. Search by google_id
        $user = User::where('google_id', $googleId)->first();

        // 2. If not found by google_id, search by verified email
        if (!$user) {
            $user = User::where('email', $email)->first();

            if ($user) {
                // Link Google account to existing user record
                $user->google_id = $googleId;
                if ($user->auth_provider === 'local' && empty($user->password_hash)) {
                    $user->auth_provider = 'google';
                }
                $user->save();
            }
        }

        $statusCode = Response::HTTP_OK;

        // 3. If user does not exist at all, auto-register
        if (!$user) {
            $user = User::create([
                'name' => $name,
                'email' => $email,
                'password_hash' => null,
                'phone' => null,
                'role' => 'customer',
                'auth_provider' => 'google',
                'google_id' => $googleId,
            ]);

            $statusCode = Response::HTTP_CREATED;
        }

        // Issue Sanctum Bearer Token
        $token = $user->createToken('auth-token', ['role:' . $user->role])->plainTextToken;

        return response()->json([
            'message' => $statusCode === Response::HTTP_CREATED ? 'Google registration successful.' : 'Google login successful.',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'phone' => $user->phone,
                'auth_provider' => $user->auth_provider,
            ],
        ], $statusCode);
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
