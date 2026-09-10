<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UsersTable;
use App\Services\FirebaseService;
use Illuminate\Http\Request;

class UsersTableController extends Controller
{
    /**
     * Get all users_table entries from Laravel DB.
     */
    public function index()
    {
        return response()->json(UsersTable::all());
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

        // Sync to Firebase Cloud Firestore
        FirebaseService::syncUsersTable($user);

        return response()->json([
            'message' => 'User saved successfully to Laravel DB and synced to Firebase',
            'user' => $user,
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
