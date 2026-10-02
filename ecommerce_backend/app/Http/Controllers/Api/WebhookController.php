<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\Payment;
use App\Models\PaymentTransaction;
use App\Services\FirebaseService;
use Illuminate\Support\Facades\Log;

class WebhookController extends Controller
{
    /**
     * PayMongo Webhook Handler.
     */
    public function handlePaymongo(Request $request)
    {
        $payload = $request->all();
        $eventType = $payload['data']['attributes']['type'] ?? null;
        
        Log::info('PayMongo Webhook Received: ' . $eventType);

        if ($eventType === 'link.payment.paid') {
            $linkId = $payload['data']['attributes']['data']['id'];
            
            $payment = Payment::where('gateway_reference_id', $linkId)->first();

            if ($payment) {
                PaymentTransaction::create([
                    'payment_id' => $payment->id,
                    'event_name' => $eventType,
                    'raw_webhook_payload' => json_encode($payload)
                ]);

                $payment->update(['status' => 'succeeded']);
                $payment->order->update([
                    'status' => 'preparing',
                    'payment_status' => 'paid',
                ]);

                FirebaseService::syncOrder($payment->order);
            }
        }

        return response()->json(['status' => 'success']);
    }
}
