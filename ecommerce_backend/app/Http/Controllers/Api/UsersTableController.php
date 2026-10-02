<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\SupabaseService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class UsersTableController extends Controller
{
    /**
     * GET /api/users-table
     * Fetch all user profiles directly from the `users` table (Supabase PostgreSQL).
     */
    public function index(): JsonResponse
    {
        try {
            $users = User::orderBy('created_at', 'desc')
                ->get()
                ->map(function ($u) {
                    $nameParts = explode(' ', trim($u->name ?? ''));
                    $firstName = $u->first_name ?: ($nameParts[0] ?? '');
                    $lastName = $u->last_name ?: (count($nameParts) > 1 ? implode(' ', array_slice($nameParts, 1)) : '');

                    return [
                        'user_id'       => $u->user_id,
                        'first_name'    => $firstName,
                        'last_name'     => $lastName,
                        'middle_name'   => $u->middle_name ?? '',
                        'email_address' => $u->email_address ?? $u->email ?? '',
                        'phone_number'  => $u->phone_num ?? $u->phone ?? '',
                        'address'       => $u->address ?? '',
                        'birthday'      => $u->birthday ?? '',
                        'role'          => $u->role ?? 'customer',
                        'user_role'     => $u->role ?? 'customer',
                        'auth_provider' => $u->auth_provider ?? 'local',
                        'created_at'    => $u->created_at?->toIso8601String(),
                    ];
                });

            return response()->json($users, Response::HTTP_OK);
        } catch (\Throwable $e) {
            Log::error('UsersTableController::index error: ' . $e->getMessage());
            return response()->json([], Response::HTTP_OK);
        }
    }

    /**
     * POST /api/users-table
     * Create or update a user profile in Supabase users_table (profile store).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email_address' => 'required|email|max:150',
            'first_name'    => 'required|string|max:100',
            'middle_name'   => 'nullable|string|max:100',
            'last_name'     => 'required|string|max:100',
            'birthday'      => 'nullable|string|max:50',
            'address'       => 'nullable|string|max:255',
            'phone_number'  => 'nullable|string|max:50',
            'user_role'     => 'nullable|string|in:customer,admin',
        ]);

        // Update the `users` table (main auth table) if user exists
        $user = User::where('email_address', $validated['email_address'])
            ->orWhere('email', $validated['email_address'])
            ->first();

        if ($user) {
            $user->first_name  = $validated['first_name'];
            $user->last_name   = $validated['last_name'];
            $user->address     = $validated['address'] ?? $user->address;
            $user->phone_num   = $validated['phone_number'] ?? $user->phone_num;
            $user->birthday    = $validated['birthday'] ?? $user->birthday;
            if (!empty($validated['user_role'])) {
                $user->role = $validated['user_role'];
            }
            $user->save();

            return response()->json([
                'message' => 'User updated successfully',
                'user'    => [
                    'email_address' => $user->email_address,
                    'first_name'    => $user->first_name,
                    'last_name'     => $user->last_name,
                    'user_role'     => $user->role,
                ],
            ], Response::HTTP_CREATED);
        }

        return response()->json(['message' => 'User not found in users table'], Response::HTTP_NOT_FOUND);
    }

    /**
     * PATCH /api/users-table/{email}/role
     * Promote or demote a user's role in the `users` table.
     */
    public function updateRole(Request $request, string $email): JsonResponse
    {
        $validated = $request->validate([
            'user_role' => 'required|string|in:customer,admin',
        ]);

        $email = urldecode($email);

        $user = User::where('email_address', $email)
            ->orWhere('email', $email)
            ->first();

        if (!$user) {
            return response()->json(['message' => 'User not found'], Response::HTTP_NOT_FOUND);
        }

        $user->role = $validated['user_role'];
        $user->save();

        return response()->json([
            'message'   => "User role updated to {$validated['user_role']}",
            'email'     => $email,
            'user_role' => $user->role,
        ], Response::HTTP_OK);
    }

    /**
     * DELETE /api/users-table/{email}
     * Delete a user from the `users` table.
     */
    public function destroy(string $emailDocId): JsonResponse
    {
        $email = urldecode($emailDocId);

        $user = User::where('email_address', $email)
            ->orWhere('email', $email)
            ->first();

        if ($user) {
            $user->delete();
            return response()->json(['message' => 'User deleted successfully'], Response::HTTP_OK);
        }

        return response()->json(['message' => 'User not found'], Response::HTTP_OK);
    }
}
