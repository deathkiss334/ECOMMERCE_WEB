<?php

namespace App\Services;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\ProductTable;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderService
{
    /**
     * Create an order in the database.
     */
    public static function createOrder(array $data): array
    {
        return DB::transaction(function () use ($data) {
            $customerName = trim($data['customer_name'] ?? 'Customer');
            $rawEmail = $data['customer_email'] ?? $data['email_address'] ?? $data['email'] ?? null;
            $customerEmail = (!empty($rawEmail) && trim($rawEmail) !== '') ? strtolower(trim($rawEmail)) : null;
            $customerPhone = $data['customer_phone'] ?? '';
            $deliveryAddress = $data['delivery_address'] ?? '';

            // 1. Resolve User ID from users table
            $userId = null;
            if ($customerEmail) {
                try {
                    $user = DB::table('users')->where(function ($q) use ($customerEmail) {
                        $q->where('email_address', $customerEmail)
                          ->orWhere('email', $customerEmail);
                    })->first();

                    if ($user) {
                        $userId = $user->user_id ?? $user->id ?? null;
                    }
                } catch (\Throwable $e) {}
            }

            // 2. Validate Items & Compute Prices
            $subtotal = 0.0;
            $orderItems = [];

            $items = $data['items'] ?? [];
            foreach ($items as $item) {
                $itemId = $item['id'] ?? null;
                $itemName = $item['name'] ?? null;
                $qty = max(1, (int) ($item['qty'] ?? $item['quantity'] ?? 1));

                // Find product by id or name defensively
                $prod = null;
                if ($itemId) {
                    try {
                        $prod = ProductTable::where('product_id', (string) $itemId)->first();
                    } catch (\Throwable $e) {}

                    if (!$prod && is_numeric($itemId)) {
                        try {
                            $prod = Product::find((int) $itemId);
                        } catch (\Throwable $e) {}
                    }
                }
                if (!$prod && $itemName) {
                    try {
                        $prod = ProductTable::where('product_type', 'like', "%{$itemName}%")->first();
                    } catch (\Throwable $e) {}
                    if (!$prod) {
                        try {
                            $prod = Product::where('name', 'like', "%{$itemName}%")->first();
                        } catch (\Throwable $e) {}
                    }
                }

                $price = $prod ? (float) ($prod->product_price ?? $prod->base_price) : (float) ($item['price'] ?? 140.00);
                $pName = $prod ? ($prod->product_type ?? $prod->name) : ($itemName ?? 'Delicious Meal');
                $lineTotal = $price * $qty;
                $subtotal += $lineTotal;

                $prodId = null;
                if ($prod) {
                    $rawPid = $prod->product_id ?? $prod->id ?? null;
                    if ($rawPid && is_numeric($rawPid)) {
                        $candidateId = (int) $rawPid;
                        try {
                            if (DB::table('products')->where('product_id', $candidateId)->exists()) {
                                $prodId = $candidateId;
                            }
                        } catch (\Throwable $e) {}
                    }
                }

                $orderItems[] = [
                    'product_id' => $prodId,
                    'product_variant_id' => null,
                    'product_name' => $pName,
                    'product_name_snapshot' => $pName,
                    'variant_name_snapshot' => 'Standard',
                    'unit_price' => $price,
                    'quantity' => $qty,
                    'subtotal' => $lineTotal,
                    'total_price' => $lineTotal,
                ];
            }

            // 3. Order Type & Delivery Fee
            $rawOrderType = strtoupper($data['order_type'] ?? 'DELIVERY');
            $isDelivery = !in_array($rawOrderType, ['PICKUP', 'DINE_IN', 'DINE-IN', 'TAKEOUT']);
            $orderType = $isDelivery ? 'DELIVERY' : 'DINE_IN';
            $deliveryFee = $isDelivery ? 49.00 : 0.00;
            $totalAmount = $subtotal + $deliveryFee;

            // 4. Generate Order Number
            $orderNumber = 'DASMA-' . strtoupper(Str::random(6));
            $paymentMethod = strtolower($data['payment_method'] ?? 'cod');
            $status = ($paymentMethod === 'cod') ? 'PREPARING' : 'PAYMENT_PENDING';
            $paymentStatus = 'unpaid';

            $notes = $isDelivery 
                ? ('Deliver to: ' . $deliveryAddress . ($customerPhone ? " ($customerPhone)" : '')) 
                : 'Dine-in / Pickup';

            // 5. Create Order
            $order = Order::create([
                'order_number' => $orderNumber,
                'user_id' => $userId,
                'customer_id' => $userId,
                'customer_name' => $customerName,
                'customer_email' => $customerEmail,
                'order_type' => $orderType,
                'status' => $status,
                'payment_status' => $paymentStatus,
                'payment_method' => $paymentMethod,
                'subtotal' => $subtotal,
                'delivery_fee' => $deliveryFee,
                'discount_amount' => 0.00,
                'total_amount' => $totalAmount,
                'total_paid' => $totalAmount,
                'notes' => $notes,
            ]);

            // 6. Create Order Items
            foreach ($orderItems as $oi) {
                $oi['order_id'] = $order->order_id;
                OrderItem::create($oi);
            }

            // 7. Create Payment Record
            $payment = Payment::create([
                'payment_id' => (string) Str::uuid(),
                'order_id' => $order->order_id,
                'payment_method' => $paymentMethod,
                'amount' => $totalAmount,
                'status' => 'pending',
                'payment_status' => 'pending',
                'gateway' => $paymentMethod === 'cod' ? 'cod' : 'gcash_manual',
            ]);

            // Load fresh order with items and latest payment
            $order->load(['items', 'latestPayment']);

            return self::formatOrder($order);
        });
    }

    /**
     * Find an order by order_number or order_id.
     */
    public static function findOrder(string $identifier): ?array
    {
        $query = Order::with(['items', 'latestPayment'])
            ->where(function ($q) use ($identifier) {
                $q->where('order_number', $identifier)
                  ->orWhere('order_number', strtoupper($identifier));
                if (ctype_digit((string) $identifier) && (int) $identifier > 0) {
                    $q->orWhere('order_id', (int) $identifier);
                }
            });

        $order = $query->first();

        return $order ? self::formatOrder($order) : null;
    }

    /**
     * Update order status and attributes.
     */
    public static function updateOrderStatus(string $identifier, string $newStatus, array $extra = []): ?array
    {
        $query = Order::with(['items', 'latestPayment'])
            ->where(function ($q) use ($identifier) {
                $q->where('order_number', $identifier)
                  ->orWhere('order_number', strtoupper($identifier));
                if (ctype_digit((string) $identifier) && (int) $identifier > 0) {
                    $q->orWhere('order_id', (int) $identifier);
                }
            });

        $order = $query->first();

        if (!$order) {
            return null;
        }

        $order->status = strtoupper($newStatus);

        if ($order->status === 'DELIVERED') {
            $order->payment_status = 'paid';
        }

        if (isset($extra['payment_status'])) {
            $order->payment_status = $extra['payment_status'];
        }

        if (isset($extra['rejection_reason'])) {
            $order->rejection_reason = $extra['rejection_reason'];
        }

        if (isset($extra['receipt_image_url'])) {
            $order->receipt_image_url = $extra['receipt_image_url'];
        }

        if (isset($extra['gcash_ref_number'])) {
            $order->gcash_ref_number = $extra['gcash_ref_number'];
        }

        if (isset($extra['lalamove_tracking_url'])) {
            $order->lalamove_tracking_url = $extra['lalamove_tracking_url'];
        }

        if (isset($extra['admin_notes'])) {
            $order->admin_notes = $extra['admin_notes'];
        }

        if (isset($extra['verified_at'])) {
            $order->verified_at = $extra['verified_at'];
        }

        $order->save();

        if ($order->latestPayment) {
            $order->latestPayment->status = $order->payment_status === 'paid' 
                ? 'paid' 
                : ($order->payment_status === 'awaiting_verification' 
                    ? 'pending_verification' 
                    : ($order->payment_status === 'rejected' ? 'failed' : 'pending'));
            if (isset($extra['gcash_ref_number'])) {
                $order->latestPayment->gateway_reference_id = $extra['gcash_ref_number'];
            }
            $order->latestPayment->save();
        }

        return self::formatOrder($order->fresh()->load(['items', 'latestPayment']));
    }

    /**
     * List orders with optional filters.
     */
    public static function listOrders(
        ?string $email = null, 
        ?array $orderNumbers = null, 
        ?string $phone = null, 
        ?string $status = null,
        bool $allowAll = false
    ): array {
        $query = Order::with(['items', 'latestPayment'])->orderBy('created_at', 'desc');

        if ($status && $status !== 'all') {
            $query->where('status', strtoupper($status));
        }

        $hasFilter = false;

        // 1. Logged in customer filter: search by customer email strictly
        if ($email && trim($email) !== '') {
            $hasFilter = true;
            $targetEmail = strtolower(trim($email));
            $query->whereRaw('LOWER(customer_email) = ?', [$targetEmail]);
        } elseif ($orderNumbers && !empty($orderNumbers)) {
            // 2. Guest customer filter: search ONLY by specific guest order numbers on this device
            // Strict Isolation: Guests can NEVER see orders belonging to registered accounts!
            $hasFilter = true;
            $query->whereIn('order_number', $orderNumbers)
                  ->whereNull('user_id');

            try {
                $registeredEmails = DB::table('users')
                    ->whereNotNull('email')
                    ->pluck('email')
                    ->map(fn($e) => strtolower(trim($e)))
                    ->filter()
                    ->toArray();

                $registeredEmailAddresses = DB::table('users')
                    ->whereNotNull('email_address')
                    ->pluck('email_address')
                    ->map(fn($e) => strtolower(trim($e)))
                    ->filter()
                    ->toArray();

                $allRegisteredEmails = array_values(array_unique(array_merge($registeredEmails, $registeredEmailAddresses)));

                if (!empty($allRegisteredEmails)) {
                    $query->where(function ($q) use ($allRegisteredEmails) {
                        $q->whereNull('customer_email')
                          ->orWhereNotIn(DB::raw('LOWER(customer_email)'), $allRegisteredEmails);
                    });
                }
            } catch (\Throwable $e) {}
        } elseif ($phone && trim($phone) !== '') {
            $hasFilter = true;
            $query->where('notes', 'like', "%{$phone}%");
        }

        // If no filter is provided and not admin (allowAll = false), return empty array
        if (!$hasFilter && !$allowAll) {
            return [];
        }

        $orders = $query->get();

        return $orders->map(fn ($o) => self::formatOrder($o))->toArray();
    }

    /**
     * Normalize Order model into array matching Flutter OrderModel.fromJson.
     */
    public static function formatOrder(Order $order): array
    {
        $items = ($order->items ?? collect())->map(fn ($i) => [
            'id' => $i->od_id ?? $i->id,
            'od_id' => $i->od_id ?? $i->id,
            'product_name' => $i->product_name_snapshot ?? 'Item',
            'product_name_snapshot' => $i->product_name_snapshot ?? 'Item',
            'variant_name' => $i->variant_name_snapshot ?? 'Standard',
            'variant_name_snapshot' => $i->variant_name_snapshot ?? 'Standard',
            'unit_price' => (float) $i->unit_price,
            'quantity' => (int) $i->quantity,
            'total_price' => (float) $i->total_price,
        ])->toArray();

        return [
            'id' => $order->order_id,
            'order_id' => (string) $order->order_id,
            'user_id' => $order->user_id,
            'customer_id' => $order->customer_id ?? $order->user_id,
            'order_number' => $order->order_number,
            'orderId' => $order->order_number,
            'status' => strtoupper($order->status),
            'payment_status' => $order->payment_status ?? 'unpaid',
            'order_type' => $order->order_type ?? 'DELIVERY',
            'delivery_fee' => (float) ($order->delivery_fee ?? 0.0),
            'subtotal' => (float) ($order->subtotal ?? 0.0),
            'total_amount' => (float) ($order->total_amount ?? 0.0),
            'totalAmount' => (float) ($order->total_amount ?? 0.0),
            'total_paid' => (float) ($order->total_paid ?? $order->total_amount ?? 0.0),
            'notes' => $order->notes ?? '',
            'created_at' => ($order->created_at instanceof \DateTimeInterface) ? $order->created_at->format('c') : (string) ($order->created_at ?? now()->toIso8601String()),
            'payment_method' => $order->payment_method ?? ($order->latestPayment->payment_method ?? 'cod'),
            'customer_name' => $order->customer_name ?? '',
            'customer_email' => $order->customer_email ?? '',
            'gcash_ref_number' => $order->gcash_ref_number ?? null,
            'receipt_image_url' => $order->receipt_image_url 
                ? (str_starts_with($order->receipt_image_url, 'http') ? $order->receipt_image_url : url('/api/receipts/' . basename($order->receipt_image_url))) 
                : null,
            'admin_notes' => $order->admin_notes ?? null,
            'rejection_reason' => $order->rejection_reason ?? null,
            'verified_at' => ($order->verified_at instanceof \DateTimeInterface) ? $order->verified_at->format('c') : ($order->verified_at ? (string) $order->verified_at : null),
            'lalamove_tracking_url' => $order->lalamove_tracking_url ?? null,
            'items' => $items,
            'latest_payment' => $order->latestPayment ? [
                'payment_id' => $order->latestPayment->payment_id,
                'payment_method' => $order->latestPayment->payment_method,
                'amount' => (float) $order->latestPayment->amount,
                'status' => $order->latestPayment->status,
                'gateway_reference_id' => $order->latestPayment->gateway_reference_id,
            ] : null,
        ];
    }
}
