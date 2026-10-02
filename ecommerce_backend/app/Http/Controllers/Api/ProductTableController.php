<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ProductTable;
use App\Services\FirebaseService;
use Illuminate\Http\Request;

class ProductTableController extends Controller
{
    /**
     * Get all product_table records for Product Management.
     */
    public function index()
    {
        return response()->json(ProductTable::all());
    }

    /**
     * Return product_table records in the storefront product response shape.
     */
    public function catalog()
    {
        return response()->json(ProductTable::query()->get()->map(
            fn (ProductTable $product) => $this->toCatalogResponse($product)
        ));
    }

    public function catalogItem(string $slug)
    {
        $product = ProductTable::query()->get()->first(
            fn (ProductTable $product) => $this->toCatalogResponse($product)['slug'] === $slug
        );

        abort_unless($product, 404);

        return response()->json($this->toCatalogResponse($product));
    }

    /**
    * Store or update a product_table record.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'product_id' => 'required|string|max:100',
            'product_quantity' => 'required|integer|min:0',
            'product_type' => 'required|string|max:100',
            'product_price' => 'required|numeric|min:0',
            'product_image' => 'nullable|string',
        ]);

        $product = ProductTable::updateOrCreate(
            ['product_id' => $validated['product_id']],
            $validated
        );

        FirebaseService::syncProductTable($product);

        return response()->json([
            'message' => 'Product saved successfully to product_table',
            'product' => $product,
        ], 201);
    }

    /**
    * Update a product_table record.
     */
    public function update(Request $request, $id)
    {
        $product = ProductTable::where('product_id', $id)->firstOrFail();

        $validated = $request->validate([
            'product_quantity' => 'sometimes|integer|min:0',
            'product_type' => 'sometimes|string|max:100',
            'product_price' => 'sometimes|numeric|min:0',
            'product_image' => 'nullable|string',
        ]);

        $product->update($validated);

        FirebaseService::syncProductTable($product);

        return response()->json([
            'message' => 'Product updated successfully in product_table',
            'product' => $product,
        ]);
    }

    /**
    * Delete a product_table record.
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

    private function toCatalogResponse(ProductTable $product): array
    {
        return [
            'id' => ctype_digit((string) $product->product_id) ? (int) $product->product_id : 0,
            'product_id' => (string) $product->product_id,
            'name' => $product->product_type,
            'slug' => \Illuminate\Support\Str::slug($product->product_type) . '-' . $product->product_id,
            'description' => $product->product_type,
            'base_price' => (float) $product->product_price,
            'rating_avg' => 0,
            'total_reviews' => 0,
            'is_active' => true,
            'is_featured' => false,
            'variants' => [],
            'images' => $product->product_image ? [['url' => $product->product_image]] : [],
        ];
    }
}
