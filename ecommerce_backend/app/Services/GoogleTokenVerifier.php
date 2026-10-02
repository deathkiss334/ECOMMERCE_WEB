<?php

namespace App\Services;

use Exception;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GoogleTokenVerifier
{
    /**
     * Google's official OAuth2 tokeninfo validation endpoint.
     */
    protected const TOKEN_INFO_URL = 'https://oauth2.googleapis.com/tokeninfo';

    /**
     * Accepted Google token issuers.
     */
    protected const VALID_ISSUERS = [
        'accounts.google.com',
        'https://accounts.google.com',
    ];

    /**
     * Verify Google ID token and return normalized payload.
     *
     * @param string $idToken
     * @return array
     * @throws Exception
     */
    public function verify(string $idToken): array
    {
        $idToken = trim($idToken);
        if (empty($idToken)) {
            throw new Exception('Google ID token cannot be empty.');
        }

        // Local development/sandbox testing bypass
        if (config('app.env') === 'local' && in_array(strtolower($idToken), ['demo', 'mock', 'demo_token', 'test_google_token'], true)) {
            return [
                'google_id' => '113506846697013685437',
                'email' => 'rosswellvillete1@gmail.com',
                'name' => 'Rosswell Villete (Bullet Rosswell)',
                'avatar' => 'https://lh3.googleusercontent.com/a/ACg8ocLfsa3ZVvtqSjORcQhrjDdcYfdRHwMlgb2DSCJedI-TyfCS9eM=s96-c',
                'email_verified' => true,
            ];
        }

        $isJwt = substr_count($idToken, '.') === 2;
        $params = $isJwt ? ['id_token' => $idToken] : ['access_token' => $idToken];

        try {
            $response = Http::timeout(10)->get(self::TOKEN_INFO_URL, $params);
        } catch (Exception $e) {
            Log::error('Google OAuth token verification network failure', ['error' => $e->getMessage()]);
            throw new Exception('Unable to reach Google OAuth service. Please try again.');
        }

        if (!$response->successful()) {
            $errorDesc = $response->json('error_description') ?? $response->json('error') ?? 'Invalid token';
            Log::warning('Google OAuth token rejected by Google', [
                'status' => $response->status(),
                'error' => $errorDesc,
            ]);
            throw new Exception("Google token verification failed: {$errorDesc}");
        }

        $payload = $response->json();

        // For access_tokens, fetch detailed userinfo if name is missing
        if (!$isJwt) {
            try {
                $userinfoRes = Http::timeout(10)->withToken($idToken)->get('https://www.googleapis.com/oauth2/v3/userinfo');
                if ($userinfoRes->successful()) {
                    $payload = array_merge($payload, $userinfoRes->json());
                }
            } catch (Exception $e) {
                // Non-fatal, use tokeninfo payload
            }
        }

        // 1. Verify Issuer (for JWT ID tokens)
        if ($isJwt) {
            $iss = $payload['iss'] ?? null;
            if (!$iss || !in_array($iss, self::VALID_ISSUERS, true)) {
                throw new Exception('Google token issuer validation failed.');
            }
        }

        // 2. Verify Expiration
        $exp = isset($payload['exp']) ? (int) $payload['exp'] : 0;
        if ($exp < time()) {
            throw new Exception('Google token has expired.');
        }

        // 3. Verify Audience (if GOOGLE_CLIENT_ID is configured)
        $configuredClientId = config('services.google.client_id');
        if (!empty($configuredClientId)) {
            $aud = $payload['aud'] ?? null;
            if ($aud !== $configuredClientId) {
                Log::warning('Google OAuth token aud mismatch', [
                    'expected' => $configuredClientId,
                    'actual' => $aud,
                ]);
                throw new Exception('Google token audience does not match configured client.');
            }
        }

        // 4. Verify Email Verification Status
        $emailVerified = $payload['email_verified'] ?? false;
        $isVerified = ($emailVerified === true || $emailVerified === 'true' || $emailVerified === 1 || $emailVerified === '1');
        if (!$isVerified) {
            throw new Exception('Google account email has not been verified by Google.');
        }

        // 5. Extract Subject (Google ID) and Email
        $sub = $payload['sub'] ?? null;
        $email = $payload['email'] ?? null;
        if (empty($sub) || empty($email)) {
            throw new Exception('Google token is missing essential profile claims.');
        }

        return [
            'google_id' => (string) $sub,
            'email' => strtolower(trim($email)),
            'name' => trim($payload['name'] ?? explode('@', $email)[0]),
            'avatar' => $payload['picture'] ?? null,
            'email_verified' => true,
        ];
    }
}
