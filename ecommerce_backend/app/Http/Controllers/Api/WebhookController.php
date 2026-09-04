<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Payment;
use App\Models\PaymentTransaction;
use Illuminate\Support\Facades\Log;

class WebhookController extends Controller
{
    public function handlePaymongo(Request $request)
    {
        // For a production app, verify the PayMongo-Signature here. 
        // We will directly process the JSON body for the class project scope.
                
        $payload = $request->all();
        $eventType = $payload['data']['attributes']['type'] ?? null;
        
        Log::info('PayMongo Webhook Received: ' . $eventType);

        if ($eventType === 'link.payment.paid') {
            $linkId = $payload['data']['attributes']['data']['id']; // Original Link ID
            
            // Find the pending payment matching this PayMongo link
            $payment = Payment::where('gateway_reference_id', $linkId)->first();

            if ($payment) {
                // Log the transaction
                PaymentTransaction::create([
                    'payment_id' => $payment->id,
                    'event_name' => $eventType,
                    'raw_webhook_payload' => json_encode($payload)
                ]);

                // Update models to Paid and Processing
                $payment->update(['status' => 'succeeded']);
                $payment->order->update([
                    'status' => 'preparing',
                    'payment_status' => 'paid',
                ]);
            }
        }

        return response()->json(['status' => 'success']);
    }
}
