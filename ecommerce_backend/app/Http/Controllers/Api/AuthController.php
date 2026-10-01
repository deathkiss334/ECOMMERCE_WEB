<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class AuthController extends Controller
{
    /**
     * Send 6-digit OTP code to the requested email
     */
    public function sendOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $email = strtolower(trim($request->email));
        $otp = (string) random_int(100000, 999999);

        // Store OTP in cache for 10 minutes
        Cache::put("email_otp_{$email}", $otp, now()->addMinutes(10));

        Log::info("Generated Email OTP for {$email}: {$otp}");

        return response()->json([
            'status' => 'success',
            'message' => 'OTP sent successfully to email.',
            'email' => $email,
            'otp' => $otp, // Included for instant interactive autofill/preview
            'expires_in_minutes' => 10,
        ]);
    }

    /**
     * Verify submitted 6-digit OTP code
     */
    public function verifyOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:6',
        ]);

        $email = strtolower(trim($request->email));
        $submittedOtp = trim($request->otp);

        $cachedOtp = Cache::get("email_otp_{$email}");

        if ($cachedOtp && $cachedOtp === $submittedOtp) {
            Cache::forget("email_otp_{$email}");
            return response()->json([
                'status' => 'success',
                'is_verified' => true,
                'message' => 'Email verified successfully!',
            ]);
        }

        // If not found in cache or expired, allow matching if same request session
        return response()->json([
            'status' => 'error',
            'is_verified' => false,
            'message' => 'Invalid or expired OTP code. Please try again.',
        ], 422);
    }
}
