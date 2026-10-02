<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Services\OrderService;
use Illuminate\Support\Str;

class QrPaymentController extends Controller
{
    /**
     * POST /api/orders/:orderId/upload-receipt
     */
    public function uploadReceipt(Request $request, $orderId = null)
    {
        $id = $orderId ?? $request->input('order_number') ?? $request->input('orderId');

        $request->validate([
            'receipt' => 'nullable',
            'receipt_image' => 'nullable',
            'receipt_base64' => 'nullable|string',
            'gcash_ref_number' => 'nullable|string',
            'reference_number' => 'nullable|string',
        ]);

        $order = OrderService::findOrder((string) $id);
        if (!$order) {
            abort(404, 'Order not found');
        }

        $receiptUrl = $order['receipt_image_url'] ?? null;
        $destination = public_path('uploads/receipts');
        if (!file_exists($destination)) {
            @mkdir($destination, 0755, true);
        }

        // 1. Try uploaded multipart file
        $file = null;
        if ($request->hasFile('receipt') && $request->file('receipt')->isValid()) {
            $file = $request->file('receipt');
        } elseif ($request->hasFile('receipt_image') && $request->file('receipt_image')->isValid()) {
            $file = $request->file('receipt_image');
        }

        if ($file) {
            $ext = $file->getClientOriginalExtension() ?: 'png';
            $filename = 'receipt_' . Str::random(12) . '.' . $ext;
            $file->move($destination, $filename);
            $receiptUrl = '/uploads/receipts/' . $filename;
        } elseif ($request->filled('receipt_base64')) {
            // 2. Fallback to base64 payload if multipart upload is restricted
            $base64Data = (string) $request->input('receipt_base64');
            $ext = 'png';
            if (preg_match('/^data:image\/(\w+);base64,/', $base64Data, $type)) {
                $base64Data = substr($base64Data, strpos($base64Data, ',') + 1);
                $ext = strtolower($type[1]);
            }
            $decoded = base64_decode($base64Data);
            if ($decoded !== false && strlen($decoded) > 0) {
                $filename = 'receipt_' . Str::random(12) . '.' . $ext;
                @file_put_contents($destination . DIRECTORY_SEPARATOR . $filename, $decoded);
                $receiptUrl = '/uploads/receipts/' . $filename;
            }
        }

        $refNumber = $request->input('gcash_ref_number') 
            ?? $request->input('reference_number') 
            ?? ($order['gcash_ref_number'] ?? null);

        $updated = OrderService::updateOrderStatus((string) $id, 'AWAITING_VERIFICATION', [
            'payment_status' => 'awaiting_verification',
            'gcash_ref_number' => $refNumber,
            'receipt_image_url' => $receiptUrl,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Payment receipt uploaded successfully! Store admin is verifying your payment.',
            'orderId' => $updated['order_number'],
            'order_number' => $updated['order_number'],
            'status' => 'AWAITING_VERIFICATION',
            'receipt_image_url' => $receiptUrl,
            'gcash_ref_number' => $refNumber,
        ]);
    }

    /**
     * POST /api/payments/submit-reference
     */
    public function submitReference(Request $request)
    {
        $request->validate([
            'order_number' => 'required|string',
            'reference_number' => 'required|string',
        ]);

        $orderNumber = $request->input('order_number');
        $refNumber = $request->input('reference_number');

        $order = OrderService::findOrder($orderNumber);
        if (!$order) {
            abort(404, 'Order not found');
        }

        $updated = OrderService::updateOrderStatus($orderNumber, 'AWAITING_VERIFICATION', [
            'payment_status' => 'awaiting_verification',
            'gcash_ref_number' => $refNumber,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Reference number submitted successfully! Awaiting verification.',
            'order_number' => $updated['order_number'],
            'status' => 'AWAITING_VERIFICATION',
            'gcash_ref_number' => $refNumber,
        ]);
    }

    /**
     * POST /api/payments/qr-confirm
     */
    public function confirm(Request $request)
    {
        $request->validate([
            'order_number' => 'required|string',
        ]);

        $orderNumber = $request->input('order_number');
        $order = OrderService::findOrder($orderNumber);

        if (!$order) {
            abort(404, 'Order not found');
        }

        return response()->json([
            'success' => true,
            'order_number' => $order['order_number'],
            'status' => $order['status'],
        ]);
    }
}
