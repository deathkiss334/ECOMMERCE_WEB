<?php

namespace App\Services;

use App\Models\Order;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FirebaseService
{
    /**
     * Synchronize an Order to Firebase Cloud Firestore.
     *
     * @param Order $order
     * @return bool
     */
    public static function syncOrder(Order $order): bool
    {
        $projectId = config('firebase.project_id') ?: env('FIREBASE_PROJECT_ID');

        if (empty($projectId) || !config('firebase.sync_enabled', true)) {
            Log::info("Firebase sync skipped for Order {$order->order_number}: FIREBASE_PROJECT_ID not set in .env");
            return false;
        }

        try {
            // Eager load items and payment if not already loaded
            if (!$order->relationLoaded('items')) {
                $order->load('items');
            }
            if (!$order->relationLoaded('latestPayment')) {
                $order->load('latestPayment');
            }

            // Build Firestore-compliant document structure
            $itemsArray = [];
            foreach ($order->items as $item) {
                $itemsArray[] = [
                    'mapValue' => [
                        'fields' => [
                            'product_name' => ['stringValue' => (string)$item->product_name_snapshot],
                            'variant_name' => ['stringValue' => (string)$item->variant_name_snapshot],
                            'unit_price' => ['doubleValue' => (float)$item->unit_price],
                            'quantity' => ['integerValue' => (int)$item->quantity],
                            'total_price' => ['doubleValue' => (float)$item->total_price],
                        ]
                    ]
                ];
            }

            $firestoreFields = [
                'order_number' => ['stringValue' => (string)$order->order_number],
                'status' => ['stringValue' => (string)$order->status],
                'payment_status' => ['stringValue' => (string)$order->payment_status],
                'payment_method' => ['stringValue' => (string)($order->latestPayment->payment_method ?? 'COD')],
                'subtotal' => ['doubleValue' => (float)$order->subtotal],
                'delivery_fee' => ['doubleValue' => (float)$order->delivery_fee],
                'total_amount' => ['doubleValue' => (float)$order->total_amount],
                'notes' => ['stringValue' => (string)($order->notes ?? '')],
                'items' => [
                    'arrayValue' => [
                        'values' => $itemsArray
                    ]
                ],
                'updated_at' => ['stringValue' => now()->toIso8601String()],
            ];

            $url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/orders/{$order->order_number}";

            $token = self::getAccessToken();
            $request = Http::timeout(5);

            if ($token) {
                $request = $request->withToken($token);
            }

            $response = $request->patch($url, [
                'fields' => $firestoreFields
            ]);

            if ($response->successful()) {
                Log::info("Firebase sync succeeded for Order {$order->order_number} (status: {$order->status})");
                return true;
            } else {
                Log::warning("Firebase sync returned non-200 for Order {$order->order_number}: " . $response->body());
                return false;
            }
        } catch (\Throwable $e) {
            Log::error("Firebase sync exception for Order {$order->order_number}: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Synchronize a User Profile to Firebase Cloud Firestore (users collection).
     *
     * @param array $userData
     * @return bool
     */
    public static function syncUser(array $userData): bool
    {
        $projectId = config('firebase.project_id') ?: env('FIREBASE_PROJECT_ID');

        if (empty($projectId) || !config('firebase.sync_enabled', true)) {
            Log::info("Firebase user sync skipped: FIREBASE_PROJECT_ID not set");
            return false;
        }

        $email = $userData['email_address'] ?? 'guest';
        if (empty($email) || empty($userData['is_verified'])) {
            return false;
        }

        try {
            $docId = preg_replace('/[^a-zA-Z0-9]/', '_', $email);
            $url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/users/{$docId}";

            $firestoreFields = [
                'first_name' => ['stringValue' => (string)($userData['first_name'] ?? '')],
                'second_name' => ['stringValue' => (string)($userData['second_name'] ?? '')],
                'middle_name' => ['stringValue' => (string)($userData['middle_name'] ?? '')],
                'birthday' => ['stringValue' => (string)($userData['birthday'] ?? '')],
                'address' => ['stringValue' => (string)($userData['delivery_address'] ?? $userData['address'] ?? '')],
                'phone_number' => ['stringValue' => (string)($userData['customer_phone'] ?? $userData['phone_number'] ?? '')],
                'email_address' => ['stringValue' => (string)$email],
                'is_verified' => ['booleanValue' => true],
                'updated_at' => ['stringValue' => now()->toIso8601String()],
            ];

            $token = self::getAccessToken();
            $request = Http::timeout(5);
            if ($token) {
                $request = $request->withToken($token);
            }

            $response = $request->patch($url, ['fields' => $firestoreFields]);

            if ($response->successful()) {
                Log::info("Firebase user sync succeeded for {$email}");
                return true;
            }
        } catch (\Throwable $e) {
            Log::error("Firebase user sync exception: " . $e->getMessage());
        }

        return false;
    }

    /**
     * Retrieve OAuth2 Bearer token if a Google service account JSON file is present.
     *
     * @return string|null
     */
    public static function getAccessToken(): ?string
    {
        $rawPath = config('firebase.credentials_path');
        $credentialsPath = file_exists($rawPath) ? $rawPath : base_path($rawPath);

        if (empty($credentialsPath) || !file_exists($credentialsPath)) {
            return null;
        }

        try {
            $keyData = json_decode(file_get_contents($credentialsPath), true);
            if (!$keyData || !isset($keyData['private_key'], $keyData['client_email'])) {
                return null;
            }

            // Generate JWT for Google OAuth2
            $now = time();
            $header = base64_url_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            $claimSet = base64_url_encode(json_encode([
                'iss' => $keyData['client_email'],
                'scope' => 'https://www.googleapis.com/auth/datastore',
                'aud' => 'https://oauth2.googleapis.com/token',
                'exp' => $now + 3600,
                'iat' => $now
            ]));

            $signatureInput = "$header.$claimSet";
            openssl_sign($signatureInput, $signature, $keyData['private_key'], 'SHA256');
            $jwt = $signatureInput . '.' . base64_url_encode($signature);

            $tokenResponse = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt
            ]);

            if ($tokenResponse->successful()) {
                return $tokenResponse->json()['access_token'] ?? null;
            } else {
                Log::warning("Google OAuth token request failed: " . $tokenResponse->body());
            }
        } catch (\Throwable $e) {
            Log::warning("Could not generate Google Access Token from credentials: " . $e->getMessage());
        }

        return null;
    }
}

if (!function_exists('base64_url_encode')) {
    function base64_url_encode($data) {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
