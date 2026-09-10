<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Store Dashboard - Order Management</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50 text-gray-800 font-sans">
    <nav class="bg-[#E8411E] text-white p-4 shadow-md">
        <div class="max-w-6xl mx-auto flex justify-between items-center">
            <h1 class="text-xl font-bold flex items-center gap-2">
                📦 E-Commerce Admin Dashboard
            </h1>
            <span>Store Status: Open</span>
        </div>
    </nav>

    <div class="max-w-6xl mx-auto mt-8 p-4">
        @if(session('success'))
            <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative mb-4">
                {{ session('success') }}
            </div>
        @endif

        <h2 class="text-2xl font-semibold mb-6">Live Order Fulfillment</h2>
        
        <div class="bg-white shadow rounded-lg overflow-hidden">
            <table class="min-w-full leading-normal">
                <thead>
                    <tr>
                        <th class="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Order Detail</th>
                        <th class="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Customer & Delivery</th>
                        <th class="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Items</th>
                        <th class="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Total</th>
                        <th class="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Action / Status</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($orders as $order)
                    <tr>
                        <td class="px-5 py-5 border-b border-gray-200 bg-white text-sm">
                            <p class="text-gray-900 font-bold">{{ $order->order_number }}</p>
                            <p class="text-gray-500 text-xs">{{ $order->created_at->diffForHumans() }}</p>
                            <span class="inline-block mt-1 px-2 py-1 text-xs font-bold rounded {{ $order->payment_status == 'paid' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800' }}">
                                Payment: {{ strtoupper($order->payment_status) }}
                            </span>
                        </td>
                        <td class="px-5 py-5 border-b border-gray-200 bg-white text-sm">
                            <p class="text-gray-900">{{ $order->notes }}</p>
                        </td>
                        <td class="px-5 py-5 border-b border-gray-200 bg-white text-sm">
                            <ul class="list-disc pl-4">
                                @foreach($order->items as $item)
                                    <li>{{ $item->quantity }}x {{ $item->product_name_snapshot }}</li>
                                @endforeach
                            </ul>
                        </td>
                        <td class="px-5 py-5 border-b border-gray-200 bg-white text-sm">
                            <p class="text-gray-900 font-bold">₱{{ number_format($order->total_amount, 2) }}</p>
                        </td>
                        <td class="px-5 py-5 border-b border-gray-200 bg-white text-sm">
                            <form action="/admin/orders/{{ $order->id }}/status" method="POST" class="flex gap-2 items-center">
                                @csrf
                                <select name="status" class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block p-2.5">
                                    <option value="pending" {{ $order->status == 'pending' ? 'selected' : '' }}>🕒 Pending</option>
                                    <option value="preparing" {{ $order->status == 'preparing' ? 'selected' : '' }}>🍳 Preparing</option>
                                    <option value="dispatched" {{ $order->status == 'dispatched' ? 'selected' : '' }}>🛵 Dispatched</option>
                                    <option value="completed" {{ $order->status == 'completed' ? 'selected' : '' }}>✅ Completed</option>
                                </select>
                                <button type="submit" class="bg-[#E8411E] hover:bg-orange-700 text-white font-bold py-2 px-4 rounded text-sm">
                                    Update
                                </button>
                            </form>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
            @if($orders->isEmpty())
                <div class="p-8 text-center text-gray-500">No orders have been received yet. Test the mobile app!</div>
            @endif
        </div>
    </div>
</body>
</html>
