<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\PaymentTransaction;
use App\Services\FirebaseService;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Str;

class QrPaymentController extends Controller
{
    /**
     * POST /api/orders/:orderId/upload-receipt
     * Customer submits their GCash Reference Number and uploads payment receipt screenshot.
     */
    public function uploadReceipt(Request $request, $orderId = null)
    {
        $id = $orderId ?? $request->input('order_number') ?? $request->input('orderId');

        $request->validate([
            'receipt' => 'nullable|file|mimes:jpeg,jpg,png,webp|max:5120',
            'receipt_image' => 'nullable|file|mimes:jpeg,jpg,png,webp|max:5120',
            'gcash_ref_number' => 'nullable|string',
            'reference_number' => 'nullable|string',
        ]);

        $order = Order::with('latestPayment')
            ->where('order_number', $id)
            ->orWhere('id', $id)
            ->firstOrFail();

        $file = $request->file('receipt') ?? $request->file('receipt_image');
        $receiptUrl = $order->receipt_image_url;

        if ($file) {
            $filename = 'receipt_' . Str::random(12) . '.' . $file->getClientOriginalExtension();
            $destination = public_path('uploads/receipts');
            if (!file_exists($destination)) {
                mkdir($destination, 0755, true);
            }
            $file->move($destination, $filename);
            $receiptUrl = asset('uploads/receipts/' . $filename);
        }

        $refNumber = $request->input('gcash_ref_number') 
            ?? $request->input('reference_number') 
            ?? $order->gcash_ref_number;

        if ($order->latestPayment) {
            $metadata = $order->latestPayment->metadata ?? [];
            if ($receiptUrl) {
                $metadata['receipt_url'] = $receiptUrl;
            }
            $order->latestPayment->update([
                'gateway_reference_id' => $refNumber,
                'status' => 'pending_verification',
                'metadata' => $metadata,
            ]);
        }

        $order->update([
            'status' => 'AWAITING_VERIFICATION',
            'payment_status' => 'awaiting_verification',
            'gcash_ref_number' => $refNumber,
            'receipt_image_url' => $receiptUrl,
        ]);

        PaymentTransaction::create([
            'payment_id' => $order->latestPayment->id ?? $order->id,
            'event_name' => 'gcash.receipt.uploaded',
            'raw_webhook_payload' => json_encode([
                'order_number' => $order->order_number,
                'reference_number' => $refNumber,
                'receipt_url' => $receiptUrl,
                'amount' => $order->total_amount,
                'submitted_at' => now()->toIso8601String(),
            ]),
        ]);

        FirebaseService::syncOrder($order);

        return response()->json([
            'success' => true,
            'message' => 'Payment receipt uploaded successfully! Store admin is verifying your payment.',
            'orderId' => $order->order_number,
            'status' => 'AWAITING_VERIFICATION',
            'receipt_image_url' => $receiptUrl,
            'gcash_ref_number' => $refNumber,
        ]);
    }

    /**
     * Alias for submitReference
     */
    public function submitReference(Request $request)
    {
        return $this->uploadReceipt($request, $request->input('order_number'));
    }

    /**
     * Deprecated insecure client-side confirmation.
     */
    public function confirm(Request $request)
    {
        return response()->json([
            'success' => false,
            'message' => 'Manual self-confirmation is disabled. Payment must be scanned and paid via GCash before the kitchen prepares the order.',
        ], Response::HTTP_FORBIDDEN);
    }
}
