<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ManualGcashVerificationTest extends TestCase
{
    use RefreshDatabase;

    protected ProductVariant $variant1;
    protected ProductVariant $variant2;
    protected User $adminUser;

    protected function setUp(): void
    {
        parent::setUp();

        // Seed demo customer
        User::create([
            'name' => 'Juan Dela Cruz',
            'email' => 'juan@example.com',
            'role' => 'customer',
            'auth_provider' => 'local',
            'password_hash' => bcrypt('password123'),
        ]);

        // Seed admin user
        $this->adminUser = User::create([
            'name' => 'Admin Chef',
            'email' => 'admin@dasmabites.com',
            'role' => 'admin',
            'auth_provider' => 'local',
            'password_hash' => bcrypt('AdminPassword123!'),
        ]);

        $category = Category::create([
            'name' => 'Meals',
            'slug' => 'meals',
            'is_active' => true,
        ]);

        $p1 = Product::create([
            'category_id' => $category->id,
            'name' => 'Classic Chicken Adobo Meal',
            'slug' => 'classic-chicken-adobo',
            'base_price' => 150.00,
            'is_active' => true,
        ]);

        $this->variant1 = ProductVariant::create([
            'product_id' => $p1->id,
            'name' => 'Regular',
            'price' => 150.00,
            'sku' => 'ADOBO-REG',
        ]);

        $p2 = Product::create([
            'category_id' => $category->id,
            'name' => 'Pork Sisig Rice Bowl',
            'slug' => 'pork-sisig',
            'base_price' => 165.00,
            'is_active' => true,
        ]);

        $this->variant2 = ProductVariant::create([
            'product_id' => $p2->id,
            'name' => 'Regular',
            'price' => 165.00,
            'sku' => 'SISIG-REG',
        ]);
    }

    /**
     * Test complete Manual GCash Payment & Receipt Verification Flow.
     */
    public function test_complete_manual_gcash_payment_and_verification_flow(): void
    {
        Storage::fake('public');

        // 1. Customer creates order (POST /api/orders/create)
        $createResponse = $this->postJson('/api/orders/create', [
            'items' => [
                ['id' => $this->variant1->id, 'qty' => 2], // 150 * 2 = 300
                ['id' => $this->variant2->id, 'qty' => 1], // 165 * 1 = 165
            ],
            'payment_method' => 'gcash',
            'customer_name' => 'Maria Santos',
            'customer_phone' => '09171234567',
            'delivery_address' => 'Dasmarinas City, Cavite',
        ]);

        $createResponse->assertStatus(201)
            ->assertJson([
                'success' => true,
                'totalAmount' => 465.00,
                'status' => 'PAYMENT_PENDING',
            ])
            ->assertJsonStructure([
                'orderId',
                'order_number',
                'totalAmount',
                'qr_image_url',
                'account_name',
                'account_number',
            ]);

        $orderId = $createResponse->json('orderId');

        // Verify SQLite database record
        $this->assertDatabaseHas('orders', [
            'order_number' => $orderId,
            'status' => 'PAYMENT_PENDING',
            'payment_status' => 'unpaid',
            'total_amount' => 465.00,
        ]);

        // 2. Customer uploads receipt screenshot (POST /api/orders/:orderId/upload-receipt)
        $fakeReceipt = UploadedFile::fake()->create('gcash_receipt.png', 100, 'image/png');

        $uploadResponse = $this->post("/api/orders/{$orderId}/upload-receipt", [
            'receipt' => $fakeReceipt,
            'gcash_ref_number' => '902348572834',
        ], [
            'Accept' => 'application/json',
        ]);

        $uploadResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'orderId' => $orderId,
                'status' => 'AWAITING_VERIFICATION',
                'gcash_ref_number' => '902348572834',
            ])
            ->assertJsonStructure(['receipt_image_url']);

        $receiptUrl = $uploadResponse->json('receipt_image_url');

        // Verify order status is AWAITING_VERIFICATION in SQLite
        $this->assertDatabaseHas('orders', [
            'order_number' => $orderId,
            'status' => 'AWAITING_VERIFICATION',
            'gcash_ref_number' => '902348572834',
        ]);

        // 3. Customer tracking status endpoint (GET /api/orders/:orderId/status)
        $statusResponse = $this->getJson("/api/orders/{$orderId}/status");
        $statusResponse->assertStatus(200)
            ->assertJson([
                'orderId' => $orderId,
                'totalAmount' => 465.00,
                'status' => 'AWAITING_VERIFICATION',
                'gcashRefNumber' => '902348572834',
            ]);

        // 4. Admin checks incoming orders (GET /api/admin/orders)
        $adminToken = $this->adminUser->createToken('admin')->plainTextToken;
        $adminOrdersResponse = $this->withHeader('Authorization', 'Bearer ' . $adminToken)
            ->getJson('/api/admin/orders?status=AWAITING_VERIFICATION');

        $adminOrdersResponse->assertStatus(200);
        $orderNumbers = collect($adminOrdersResponse->json())->pluck('order_number')->all();
        $this->assertContains($orderId, $orderNumbers);

        // 5. Admin Approves the GCash Receipt (PATCH /api/admin/orders/:orderId/verify)
        $approveResponse = $this->withHeader('Authorization', 'Bearer ' . $adminToken)
            ->patchJson("/api/admin/orders/{$orderId}/verify", [
                'action' => 'APPROVE',
                'notes' => 'Received ₱465.00 on GCash phone +63 985 564 4297. Cooking now.',
            ]);

        $approveResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'order' => [
                    'order_number' => $orderId,
                    'status' => 'PAID',
                    'payment_status' => 'paid',
                ],
            ]);

        // Verify verified_at is populated in SQLite
        $order = Order::where('order_number', $orderId)->first();
        $this->assertEquals('PAID', $order->status);
        $this->assertEquals('paid', $order->payment_status);
        $this->assertNotNull($order->verified_at);

        // 6. Customer tracking reflects PAID in real time
        $finalStatusResponse = $this->getJson("/api/orders/{$orderId}/status");
        $finalStatusResponse->assertStatus(200)
            ->assertJson([
                'status' => 'PAID',
                'payment_status' => 'paid',
            ]);

        // 7. Test Admin Rejection
        $rejectResponse = $this->withHeader('Authorization', 'Bearer ' . $adminToken)
            ->patchJson("/api/admin/orders/{$orderId}/verify", [
                'action' => 'REJECT',
                'notes' => 'Blurred receipt screenshot. Please re-upload.',
            ]);

        $rejectResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'order' => [
                    'status' => 'REJECTED',
                    'payment_status' => 'rejected',
                ],
            ]);
    }
}
