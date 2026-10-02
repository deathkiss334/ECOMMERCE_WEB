<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UsersTable;
use App\Services\SupabaseService;
use Illuminate\Http\Request;

class UsersTableController extends Controller
{
    /**
     * Get all users_table entries from Laravel DB.
     */
    public function index()
    {
        $usersFromUsersTable = UsersTable::all();

        $usersFromUsers = \App\Models\User::all()->map(function ($u) {
            $nameParts = explode(' ', trim($u->name ?? ''));
            $firstName = $u->first_name ?: ($nameParts[0] ?? '');
            $lastName = $u->last_name ?: (count($nameParts) > 1 ? implode(' ', array_slice($nameParts, 1)) : '');

            return [
                'first_name' => $firstName,
                'middle_name' => '',
                'last_name' => $lastName,
                'birthday' => $u->birthday ?? '',
                'address' => $u->address ?? '',
                'email_address' => $u->email_address ?: ($u->email ?? ''),
                'phone_number' => $u->phone_num ?: ($u->phone ?? ''),
                'role' => $u->role ?? 'customer',
            ];
        });

        $merged = [];
        foreach ($usersFromUsers as $u) {
            $email = strtolower(trim($u['email_address'] ?? ''));
            if ($email !== '') {
                $merged[$email] = $u;
            }
        }

        foreach ($usersFromUsersTable as $u) {
            $email = strtolower(trim($u->email_address ?? ''));
            if ($email !== '') {
                $merged[$email] = [
                    'first_name' => $u->first_name ?? '',
                    'middle_name' => $u->middle_name ?? '',
                    'last_name' => $u->last_name ?? '',
                    'birthday' => $u->birthday ?? '',
                    'address' => $u->address ?? '',
                    'email_address' => $u->email_address ?? '',
                    'phone_number' => $u->phone_number ?? '',
                    'role' => 'customer',
                ];
            }
        }

        return response()->json(array_values($merged));
    }

    /**
     * Store or update a users_table entry and sync to Firebase.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'email_address' => 'required|email|max:150',
            'first_name' => 'required|string|max:100',
            'middle_name' => 'nullable|string|max:100',
            'last_name' => 'required|string|max:100',
            'birthday' => 'nullable|string|max:50',
            'address' => 'nullable|string|max:255',
            'phone_number' => 'nullable|string|max:50',
        ]);

        $user = UsersTable::updateOrCreate(
            ['email_address' => $validated['email_address']],
            $validated
        );

        // Sync to Supabase
        SupabaseService::syncUsersTable($user);

        return response()->json([
            'message' => 'User saved successfully to Supabase',
            'user'    => $user,
        ], 201);
    }

    /**
     * Delete a users_table entry.
     */
    public function destroy($emailDocId)
    {
        $user = UsersTable::all()->first(function($u) use ($emailDocId) {
            $docId = preg_replace('/[^a-zA-Z0-9]/', '_', $u->email_address);
            return $docId === $emailDocId || $u->email_address === $emailDocId;
        });

        if ($user) {
            $user->delete();
        }

        return response()->json([
            'message' => 'User deleted successfully',
        ]);
    }
}
