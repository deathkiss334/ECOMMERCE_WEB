<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ProductTable;
use App\Services\FirebaseService;
use Illuminate\Http\Request;

class ProductTableController extends Controller
{
    /**
     * Get all product_table entries from Laravel DB.
     */
    public function index()
    {
        return response()->json(ProductTable::all());
    }

    /**
     * Store or update a product_table entry and sync to Firebase.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'product_id' => 'required|string|max:100',
            'product_quantity' => 'required|integer|min:0',
            'product_type' => 'required|string|max:100',
            'product_price' => 'required|numeric|min:0',
        ]);

        $product = ProductTable::updateOrCreate(
            ['product_id' => $validated['product_id']],
            $validated
        );

        // Sync to Firebase Cloud Firestore
        FirebaseService::syncProductTable($product);

        return response()->json([
            'message' => 'Product saved successfully to Laravel DB and synced to Firebase',
            'product' => $product,
        ], 201);
    }

    /**
     * Update a product_table entry and sync to Firebase.
     */
    public function update(Request $request, $id)
    {
        $product = ProductTable::where('product_id', $id)->firstOrFail();

        $validated = $request->validate([
            'product_quantity' => 'sometimes|integer|min:0',
            'product_type' => 'sometimes|string|max:100',
            'product_price' => 'sometimes|numeric|min:0',
        ]);

        $product->update($validated);

        // Sync to Firebase Cloud Firestore
        FirebaseService::syncProductTable($product);

        return response()->json([
            'message' => 'Product updated successfully in Laravel DB and synced to Firebase',
            'product' => $product,
        ]);
    }

    /**
     * Delete a product_table entry.
     */
    public function destroy($id)
    {
        $product = ProductTable::where('product_id', $id)->first();
        if ($product) {
            $product->delete();
        }

        return response()->json([
            'message' => 'Product deleted successfully',
        ]);
    }
}
