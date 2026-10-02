<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ProductTable;
use App\Services\SupabaseService;
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
            'product_description' => 'nullable|string',
            'product_price' => 'required|numeric|min:0',
            'product_image' => 'nullable|string',
        ]);

        $product = ProductTable::updateOrCreate(
            ['product_id' => $validated['product_id']],
            $validated
        );

        // Sync to Supabase
        SupabaseService::syncProductTable($product);

        return response()->json([
            'message' => 'Product saved successfully to Supabase',
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
            'product_description' => 'nullable|string',
            'product_price' => 'sometimes|numeric|min:0',
            'product_image' => 'nullable|string',
        ]);

        $product->update($validated);

        // Sync to Supabase
        SupabaseService::syncProductTable($product);

        return response()->json([
            'message' => 'Product updated successfully in Supabase',
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
        $id = $product->prod_id ?? $product->product_id;
        $name = $product->prod_name ?? $product->product_type ?? 'Menu Item';
        $price = (float) ($product->product_price ?? 0);
        $img = $product->prod_img ?? $product->product_image ?? 'assets/assets1.jpg';

        // Extract integer id if last characters are digits or fallback to positive crc32
        $intId = ctype_digit((string) $id) ? (int) $id : (abs(crc32((string) $id)) % 100000 + 1);

        return [
            'id' => $intId,
            'product_id' => (string) $id,
            'prod_id' => (string) $id,
            'name' => $name,
            'restaurant' => 'Storehouse Pickup',
            'slug' => \Illuminate\Support\Str::slug($name) . '-' . substr((string) $id, -4),
            'description' => $product->prod_desc ?? $product->product_description ?? '',
            'base_price' => $price,
            'price' => $price,
            'rating_avg' => (float) ($product->prod_rating ?? 4.8),
            'rating' => (float) ($product->prod_rating ?? 4.8),
            'sold' => (int) ($product->prod_quantity ?? 50),
            'badge' => $price > 200 ? 'BESTSELLER' : '',
            'category' => $product->prod_cat ?? 'Rice Dishes',
            'total_reviews' => 12,
            'is_active' => true,
            'is_featured' => true,
            'variants' => [],
            'image' => $img,
            'product_image' => $img,
            'images' => [['url' => $img]],
        ];
    }
}
