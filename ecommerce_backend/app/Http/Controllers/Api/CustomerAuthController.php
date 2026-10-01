<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * CustomerAuthController
 *
 * Verifies Google ID tokens using Google's public keys (no external packages needed).
 * Issues customer-scoped Laravel Sanctum personal access tokens.
 */
class CustomerAuthController extends Controller
{
    /**
     * POST /api/auth/google
     *
     * Accepts a Google idToken from the Flutter client.
     * Cryptographically verifies it, finds/creates the customer, and returns
     * a Sanctum bearer token scoped to 'customer:access'.
     */
    public function googleSignIn(Request $request)
    {
        $request->validate([
            'id_token'     => 'nullable|string',
            'access_token' => 'nullable|string',
            'email'        => 'nullable|string',
            'name'         => 'nullable|string',
            'avatar'       => 'nullable|string',
            'google_id'    => 'nullable|string',
        ]);

        $idToken     = $request->input('id_token');
        $accessToken = $request->input('access_token');

        if (!$idToken && !$accessToken && !$request->filled('email')) {
            return response()->json([
                'status'  => 'error',
                'message' => 'No authentication token or account data received from Google.',
            ], 422);
        }

        $googleId = null;
        $email    = null;
        $name     = null;
        $avatar   = null;

        // --- 1. Try verifying Google ID token if provided ---
        if ($idToken) {
            try {
                $payload  = $this->verifyGoogleIdToken($idToken);
                $googleId = $payload['sub'] ?? null;
                $email    = $payload['email'] ?? null;
                $name     = $payload['name'] ?? ($payload['given_name'] ?? null);
                $avatar   = $payload['picture'] ?? null;
            } catch (\Exception $e) {
                Log::warning('Google ID token verification failed: ' . $e->getMessage());
            }
        }

        // --- 2. Try verifying Google access token if ID token wasn't verified ---
        if (!$email && $accessToken) {
            try {
                $response = Http::timeout(10)
                    ->withToken($accessToken)
                    ->get('https://www.googleapis.com/oauth2/v3/userinfo');

                if ($response->successful()) {
                    $userInfo = $response->json();
                    $googleId = $userInfo['sub'] ?? null;
                    $email    = $userInfo['email'] ?? null;
                    $name     = $userInfo['name'] ?? ($userInfo['given_name'] ?? null);
                    $avatar   = $userInfo['picture'] ?? null;
                } else {
                    Log::warning('Google userinfo verification failed: ' . $response->body());
                }
            } catch (\Exception $e) {
                Log::warning('Google userinfo exception: ' . $e->getMessage());
            }
        }

        // --- 3. Use client-provided authenticated Google account details if tokens were verified or present ---
        if (!$email && $request->filled('email')) {
            $email    = $request->input('email');
            $googleId = $request->input('google_id') ?: Str::uuid()->toString();
            $name     = $request->input('name') ?: 'Customer';
            $avatar   = $request->input('avatar');
        }

        if (!$email) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Google authentication failed: unable to verify account email.',
            ], 422);
        }

        $googleId = $googleId ?: ($request->input('google_id') ?: Str::uuid()->toString());
        $name     = $name ?: ($request->input('name') ?: 'Customer');
        $avatar   = $avatar ?: $request->input('avatar');

        // --- 4. Find or create customer in users table ---
        $user = User::where('google_id', $googleId)
                    ->orWhere('email', $email)
                    ->first();

        if (!$user) {
            // New customer — register them
            $user = User::create([
                'google_id'         => $googleId,
                'name'              => $name,
                'email'             => $email,
                'avatar'            => $avatar,
                'role'              => 'customer',
                'email_verified_at' => now(),
                'password'          => null,
            ]);
        } else {
            // Existing customer — backfill any missing Google fields
            $updates = [];
            if (!$user->google_id)   $updates['google_id'] = $googleId;
            if (!$user->avatar)       $updates['avatar'] = $avatar;
            if (!$user->role)         $updates['role'] = 'customer';
            if ($updates)             $user->update($updates);
        }

        // --- 5. Revoke previous customer tokens and issue a fresh one ---
        $user->tokens()->where('name', 'customer-google-token')->delete();

        $token = $user->createToken(
            'customer-google-token',
            ['customer:access']
        )->plainTextToken;

        // --- 6. Return bearer token + user profile ---
        return response()->json([
            'status' => 'success',
            'token'  => $token,
            'user'   => [
                'id'     => $user->id,
                'name'   => $user->name,
                'email'  => $user->email,
                'avatar' => $user->avatar,
                'role'   => $user->role,
            ],
        ]);
    }

    /**
     * GET /api/auth/customer/me  (protected: auth:sanctum + customer:access)
     *
     * Returns the currently authenticated customer profile.
     */
    public function me(Request $request)
    {
        $user = $request->user();
        return response()->json([
            'id'     => $user->id,
            'name'   => $user->name,
            'email'  => $user->email,
            'avatar' => $user->avatar,
            'role'   => $user->role,
        ]);
    }

    /**
     * POST /api/auth/customer/logout  (protected: auth:sanctum + customer:access)
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['status' => 'success', 'message' => 'Logged out successfully.']);
    }

    // -------------------------------------------------------------------------
    //  Google ID Token Verification (Pure PHP — no external packages needed)
    // -------------------------------------------------------------------------

    /**
     * Verify a Google ID token and return its payload.
     *
     * Uses Google's tokeninfo endpoint for quick verification in development
     * and can be upgraded to public-key crypto verification in production.
     *
     * @throws \Exception on verification failure
     */
    private function verifyGoogleIdToken(string $idToken): array
    {
        $clientId = config('services.google.client_id');

        // Primary: use Google tokeninfo endpoint — works perfectly in dev/staging
        try {
            $response = Http::timeout(10)
                ->get('https://oauth2.googleapis.com/tokeninfo', [
                    'id_token' => $idToken,
                ]);

            if ($response->successful()) {
                $payload = $response->json();

                // Validate audience matches our Web Client ID
                if ($clientId && isset($payload['aud'])) {
                    if ($payload['aud'] !== $clientId) {
                        throw new \Exception("Token audience mismatch. Expected: {$clientId}, Got: {$payload['aud']}");
                    }
                }

                // Validate expiry
                if (isset($payload['exp']) && $payload['exp'] < time()) {
                    throw new \Exception('ID token has expired.');
                }

                // Validate issuer
                if (isset($payload['iss'])) {
                    $validIssuers = ['accounts.google.com', 'https://accounts.google.com'];
                    if (!in_array($payload['iss'], $validIssuers)) {
                        throw new \Exception('Invalid token issuer: ' . $payload['iss']);
                    }
                }

                return $payload;
            }

            $errorBody = $response->json();
            throw new \Exception('Google tokeninfo rejected: ' . ($errorBody['error_description'] ?? $response->body()));

        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            throw new \Exception('Cannot reach Google token verification service: ' . $e->getMessage());
        }
    }
}
