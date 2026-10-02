<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Symfony\Component\HttpFoundation\Response;

class UserController extends Controller
{
    /**
     * Password policy regex:
     * - Minimum 8 characters
     * - At least 1 uppercase letter
     * - At least 1 lowercase letter
     * - At least 1 digit
     * - At least 1 special character
     */
    protected const PASSWORD_REGEX = '/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#^()_+=\-\[\]{}|:;<>,.~`])[A-Za-z\d@$!%*?&#^()_+=\-\[\]{}|:;<>,.~`]{8,}$/';

    /**
     * GET /api/user/profile
     * Returns the current logged-in user's profile details.
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role' => $user->role,
                'auth_provider' => $user->auth_provider,
                'created_at' => $user->created_at?->toIso8601String(),
                'updated_at' => $user->updated_at?->toIso8601String(),
            ],
        ], Response::HTTP_OK);
    }

    /**
     * PUT /api/user/profile
     * Allows updating user's name and phone.
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        $rawName = trim((string) $request->input('name', $user->name));
        $rawPhone = $request->has('phone') ? ($request->input('phone') !== null ? trim((string) $request->input('phone')) : null) : $user->phone;

        $validator = Validator::make([
            'name' => $rawName,
            'phone' => $rawPhone,
        ], [
            'name' => ['required', 'string', 'min:2', 'max:100'],
            'phone' => ['nullable', 'string', 'max:25'],
        ], [
            'name.min' => 'Name must be at least 2 characters.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $user->name = $rawName;
        $user->phone = $rawPhone;
        $user->save();

        return response()->json([
            'message' => 'Profile updated successfully.',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role' => $user->role,
                'auth_provider' => $user->auth_provider,
                'created_at' => $user->created_at?->toIso8601String(),
                'updated_at' => $user->updated_at?->toIso8601String(),
            ],
        ], Response::HTTP_OK);
    }

    /**
     * PUT /api/user/change-password
     * Allows changing password for local auth users only.
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function changePassword(Request $request): JsonResponse
    {
        $user = $request->user();

        // 1. Guard against non-local accounts
        if ($user->auth_provider !== 'local' || empty($user->password_hash)) {
            return response()->json([
                'message' => 'Password management is only available for local password accounts.',
                'error' => 'FORBIDDEN_PROVIDER',
            ], Response::HTTP_BAD_REQUEST);
        }

        // 2. Validate inputs
        $validator = Validator::make($request->all(), [
            'current_password' => ['required', 'string'],
            'new_password' => ['required', 'string', 'min:8', 'regex:' . self::PASSWORD_REGEX],
            'confirm_new_password' => ['required', 'string', 'same:new_password'],
        ], [
            'new_password.regex' => 'New password must contain at least 1 uppercase letter, 1 lowercase letter, 1 number, and 1 special character.',
            'confirm_new_password.same' => 'The password confirmation does not match the new password.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        // 3. Constant-time verification of current password
        if (!Hash::check($request->input('current_password'), $user->password_hash)) {
            return response()->json([
                'message' => 'Current password does not match our records.',
                'error' => 'INVALID_CREDENTIALS',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        // 4. Update password hash
        $user->password_hash = Hash::make($request->input('new_password'));
        $user->save();

        return response()->json([
            'message' => 'Password changed successfully.',
        ], Response::HTTP_OK);
    }
}
