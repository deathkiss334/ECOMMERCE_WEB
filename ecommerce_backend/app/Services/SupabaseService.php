<?php

namespace App\Services;

use App\Models\Order;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * SupabaseService
 *
 * Provides static helpers to upsert/sync Laravel model data to Supabase
 * via the Supabase REST API (PostgREST).  This mirrors the pattern of the
 * old FirebaseService so swap-in is minimal: just replace
 *   FirebaseService::syncOrder($order)
 * with
 *   SupabaseService::syncOrder($order)
 *
 * All methods are non-fatal: on any failure they log the error and return
 * false so that the primary transaction is never rolled back due to sync.
 */
class SupabaseService
{
    // ──────────────────────────────────────────────────────────────────────────
    // Internal helpers
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Return a pre-configured HTTP client for Supabase REST calls.
     */
    private static function client(): \Illuminate\Http\Client\PendingRequest
    {
        return Http::withoutVerifying()
            ->timeout(8)
            ->withHeaders([
                'apikey'        => config('supabase.key'),
                'Authorization' => 'Bearer ' . config('supabase.key'),
                'Content-Type'  => 'application/json',
                'Prefer'        => 'resolution=merge-duplicates,return=minimal',
            ]);
    }

    /**
     * Build the full REST URL for a given table.
     */
    private static function tableUrl(string $table): string
    {
        return rtrim(config('supabase.rest_url'), '/') . '/' . $table;
    }

    /**
     * Guard: returns false if sync is disabled or URL is unconfigured.
     */
    private static function isEnabled(string $label): bool
    {
        if (!config('supabase.sync_enabled', true)) {
            Log::info("Supabase sync disabled — skipping {$label}.");
            return false;
        }

        if (empty(config('supabase.url'))) {
            Log::info("SUPABASE_URL not set — skipping {$label}.");
            return false;
        }

        return true;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Public sync methods
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Upsert an Order (and its items) to the Supabase `orders` table.
     *
     * The upsert is keyed on `order_number` (on_conflict=order_number).
     * Items are stored as a JSONB column `items` so no separate child
     * upsert is needed.
     */
    public static function syncOrder(Order $order): bool
    {
        if (!self::isEnabled("Order {$order->order_number}")) {
            return false;
        }

        try {
            // Eager-load relationships if missing
            if (!$order->relationLoaded('items')) {
                $order->load('items');
            }
            if (!$order->relationLoaded('latestPayment')) {
                $order->load('latestPayment');
            }

            $items = $order->items->map(fn ($item) => [
                'product_name' => (string) $item->product_name_snapshot,
                'variant_name' => (string) $item->variant_name_snapshot,
                'unit_price'   => (float)  $item->unit_price,
                'quantity'     => (int)    $item->quantity,
                'total_price'  => (float)  $item->total_price,
            ])->values()->toArray();

            $payload = [
                'order_number'      => (string) $order->order_number,
                'status'            => (string) $order->status,
                'payment_status'    => (string) $order->payment_status,
                'payment_method'    => (string) ($order->latestPayment->payment_method ?? 'COD'),
                'subtotal'          => (float)  $order->subtotal,
                'delivery_fee'      => (float)  ($order->delivery_fee ?? 0),
                'total_amount'      => (float)  $order->total_amount,
                'notes'             => (string) ($order->notes ?? ''),
                'customer_name'     => (string) ($order->customer_name ?? ''),
                'customer_email'    => (string) ($order->customer_email ?? ''),
                'order_type'        => (string) ($order->order_type ?? 'DELIVERY'),
                'gcash_ref_number'  => (string) ($order->gcash_ref_number ?? ''),
                'receipt_image_url' => (string) ($order->receipt_image_url ?? ''),
                'admin_notes'       => (string) ($order->admin_notes ?? ''),
                'rejection_reason'  => (string) ($order->rejection_reason ?? ''),
                'lalamove_tracking_url' => (string) ($order->lalamove_tracking_url ?? ''),
                'verified_at'       => $order->verified_at
                                        ? $order->verified_at->toIso8601String()
                                        : null,
                'items'             => $items,          // stored as jsonb
                'synced_at'         => now()->toIso8601String(),
            ];

            $response = self::client()
                ->withHeaders(['Prefer' => 'resolution=merge-duplicates,return=minimal'])
                ->post(self::tableUrl('orders') . '?on_conflict=order_number', $payload);

            if ($response->successful()) {
                Log::info("Supabase sync ✓ Order {$order->order_number} (status: {$order->status})");
                return true;
            }

            Log::warning("Supabase sync ✗ Order {$order->order_number}: " . $response->body());
            return false;

        } catch (\Throwable $e) {
            Log::error("Supabase syncOrder exception ({$order->order_number}): " . $e->getMessage());
            return false;
        }
    }

    /**
     * Upsert a user profile to the Supabase `profiles` table.
     *
     * Keyed on `email`. Safe to call after registration or Google login.
     */
    public static function syncUser(array $userData): bool
    {
        $email = $userData['email'] ?? $userData['email_address'] ?? null;

        if (!self::isEnabled("User {$email}") || empty($email)) {
            return false;
        }

        try {
            $payload = [
                'email'         => strtolower(trim($email)),
                'name'          => (string) ($userData['name'] ?? ''),
                'phone'         => (string) ($userData['phone'] ?? $userData['phone_num'] ?? ''),
                'role'          => (string) ($userData['role'] ?? 'customer'),
                'auth_provider' => (string) ($userData['auth_provider'] ?? 'local'),
                'google_id'     => $userData['google_id'] ?? null,
                'avatar_url'    => $userData['avatar'] ?? null,
                'is_verified'   => true,
                'synced_at'     => now()->toIso8601String(),
            ];

            $response = self::client()
                ->post(self::tableUrl('profiles') . '?on_conflict=email', $payload);

            if ($response->successful()) {
                Log::info("Supabase sync ✓ User profile {$email}");
                return true;
            }

            Log::warning("Supabase syncUser ✗ {$email}: " . $response->body());
            return false;

        } catch (\Throwable $e) {
            Log::error("Supabase syncUser exception ({$email}): " . $e->getMessage());
            return false;
        }
    }

    /**
     * Upsert a product record to the Supabase `product_table` table.
     * Mirrors the old FirebaseService::syncProductTable signature.
     *
     * @param mixed $productData  ProductTable model instance or array
     */
    public static function syncProductTable($productData): bool
    {
        $data      = is_array($productData) ? $productData : $productData->toArray();
        $productId = $data['product_id'] ?? null;

        if (!self::isEnabled("ProductTable {$productId}") || empty($productId)) {
            return false;
        }

        try {
            $payload = [
                'product_id'       => (string) $productId,
                'product_quantity' => (int)    ($data['product_quantity'] ?? 0),
                'product_type'     => (string) ($data['product_type'] ?? ''),
                'product_price'    => (float)  ($data['product_price'] ?? 0.0),
                'synced_at'        => now()->toIso8601String(),
            ];

            $response = self::client()
                ->post(self::tableUrl('product_table') . '?on_conflict=product_id', $payload);

            if ($response->successful()) {
                Log::info("Supabase sync ✓ product_table/{$productId}");
                return true;
            }

            Log::warning("Supabase syncProductTable ✗ {$productId}: " . $response->body());
            return false;

        } catch (\Throwable $e) {
            Log::error("Supabase syncProductTable exception ({$productId}): " . $e->getMessage());
            return false;
        }
    }

    /**
     * Upsert a users_table record to Supabase.
     * Mirrors the old FirebaseService::syncUsersTable signature.
     *
     * @param mixed $userData  UsersTable model instance or array
     */
    public static function syncUsersTable($userData): bool
    {
        $data  = is_array($userData) ? $userData : $userData->toArray();
        $email = $data['email_address'] ?? null;

        if (!self::isEnabled("UsersTable {$email}") || empty($email)) {
            return false;
        }

        try {
            $payload = [
                'first_name'    => (string) ($data['first_name'] ?? ''),
                'middle_name'   => (string) ($data['middle_name'] ?? ''),
                'last_name'     => (string) ($data['last_name'] ?? $data['second_name'] ?? ''),
                'birthday'      => (string) ($data['birthday'] ?? ''),
                'address'       => (string) ($data['address'] ?? ''),
                'email_address' => (string) $email,
                'phone_number'  => (string) ($data['phone_number'] ?? ''),
                'synced_at'     => now()->toIso8601String(),
            ];

            $response = self::client()
                ->post(self::tableUrl('users_table') . '?on_conflict=email_address', $payload);

            if ($response->successful()) {
                Log::info("Supabase sync ✓ users_table/{$email}");
                return true;
            }

            Log::warning("Supabase syncUsersTable ✗ {$email}: " . $response->body());
            return false;

        } catch (\Throwable $e) {
            Log::error("Supabase syncUsersTable exception ({$email}): " . $e->getMessage());
            return false;
        }
    }

    /**
     * Fetch a user by email directly from Supabase users_table via REST.
     */
    public static function getUserFromSupabase(string $email): ?array
    {
        try {
            $response = self::client()
                ->get(self::tableUrl('users_table'), [
                    'email_address' => 'eq.' . $email,
                    'select'        => '*',
                ]);

            if ($response->successful()) {
                $rows = $response->json();
                return !empty($rows) ? $rows[0] : null;
            }
        } catch (\Throwable $e) {
            Log::error("Supabase getUserFromSupabase exception ({$email}): " . $e->getMessage());
        }

        return null;
    }

    /**
     * Upsert user directly into Supabase users_table via REST.
     */
    public static function saveUserToSupabase(array $data): ?array
    {
        $email = $data['email_address'] ?? $data['email'] ?? null;
        if (empty($email)) {
            return null;
        }

        try {
            $existing = self::getUserFromSupabase($email);

            $payload = [
                'email_address' => $email,
                'first_name'    => $data['first_name'] ?? ($existing['first_name'] ?? 'User'),
                'last_name'     => $data['last_name'] ?? ($existing['last_name'] ?? ''),
                'address'       => $data['address'] ?? ($existing['address'] ?? ''),
                'phone_number'  => $data['phone_number'] ?? $data['phone'] ?? ($existing['phone_number'] ?? ''),
                'user_role'     => $data['user_role'] ?? $data['role'] ?? ($existing['user_role'] ?? 'customer'),
                'updated_at'    => now()->toIso8601String(),
            ];

            if ($existing) {
                // Update via PATCH
                $response = self::client()
                    ->patch(self::tableUrl('users_table') . '?email_address=eq.' . urlencode($email), $payload);
            } else {
                // Insert via POST
                $payload['created_at'] = now()->toIso8601String();
                $response = self::client()
                    ->post(self::tableUrl('users_table'), $payload);
            }

            if ($response->successful()) {
                return array_merge($existing ?? [], $payload);
            }

            Log::warning("Supabase saveUserToSupabase failed: " . $response->body());
        } catch (\Throwable $e) {
            Log::error("Supabase saveUserToSupabase exception: " . $e->getMessage());
        }

        return null;
    }
}
