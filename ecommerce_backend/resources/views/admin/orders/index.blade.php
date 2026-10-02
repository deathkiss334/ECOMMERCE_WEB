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
                    <tr class="{{ $order->payment_status !== 'paid' ? 'bg-amber-50/40' : '' }}">
                        <td class="px-5 py-5 border-b border-gray-200 text-sm">
                            <p class="text-gray-900 font-bold">{{ $order->order_number }}</p>
                            <p class="text-gray-500 text-xs">{{ $order->created_at->diffForHumans() }}</p>
                            
                            @if($order->payment_status === 'paid')
                                <span class="inline-block mt-1 px-2.5 py-0.5 text-xs font-bold rounded-full bg-green-100 text-green-800">
                                    ✓ PAID
                                </span>
                            @elseif($order->payment_status === 'verifying')
                                <span class="inline-block mt-1 px-2.5 py-0.5 text-xs font-bold rounded-full bg-blue-100 text-blue-800 animate-pulse">
                                    🔍 REF SUBMITTED
                                </span>
                            @else
                                <span class="inline-block mt-1 px-2.5 py-0.5 text-xs font-bold rounded-full bg-red-100 text-red-800">
                                    ⚠️ UNPAID (DO NOT COOK)
                                </span>
                            @endif

                            @if($order->latestPayment && $order->latestPayment->gateway_reference_id)
                                <div class="mt-1 text-xs text-blue-700 font-semibold bg-blue-50 px-2 py-0.5 rounded border border-blue-200 inline-block">
                                    Ref: {{ $order->latestPayment->gateway_reference_id }}
                                </div>
                            @endif
                        </td>
                        <td class="px-5 py-5 border-b border-gray-200 text-sm">
                            <p class="text-gray-900">{{ $order->notes }}</p>
                            <p class="text-xs text-gray-500 mt-1">Method: <strong class="uppercase text-gray-700">{{ $order->latestPayment->payment_method ?? 'COD' }}</strong></p>
                        </td>
                        <td class="px-5 py-5 border-b border-gray-200 text-sm">
                            <ul class="list-disc pl-4">
                                @foreach($order->items as $item)
                                    <li>{{ $item->quantity }}x {{ $item->product_name_snapshot }}</li>
                                @endforeach
                            </ul>
                        </td>
                        <td class="px-5 py-5 border-b border-gray-200 text-sm">
                            <p class="text-gray-900 font-bold text-base">₱{{ number_format($order->total_amount, 2) }}</p>
                        </td>
                        <td class="px-5 py-5 border-b border-gray-200 text-sm">
                            <div class="flex flex-col gap-2">
                                @if($order->payment_status !== 'paid' && ($order->latestPayment->payment_method ?? '') !== 'cod')
                                    <form action="/admin/orders/{{ $order->id }}/verify-payment" method="POST">
                                        @csrf
                                        <button type="submit" class="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-2 px-3 rounded text-xs flex items-center justify-center gap-1 shadow-sm transition">
                                            ✅ Verify GCash & Cook
                                        </button>
                                    </form>
                                @endif

                                <form action="/admin/orders/{{ $order->id }}/status" method="POST" class="flex gap-1.5 items-center">
                                    @csrf
                                    <select name="status" class="bg-gray-50 border border-gray-300 text-gray-900 text-xs rounded-lg focus:ring-blue-500 focus:border-blue-500 block p-2">
                                        <option value="pending" {{ $order->status == 'pending' ? 'selected' : '' }}>🕒 Pending</option>
                                        <option value="preparing" {{ $order->status == 'preparing' ? 'selected' : '' }}>🍳 Preparing</option>
                                        <option value="dispatched" {{ $order->status == 'dispatched' ? 'selected' : '' }}>🛵 Dispatched</option>
                                        <option value="completed" {{ $order->status == 'completed' ? 'selected' : '' }}>✓ Completed</option>
                                    </select>
                                    <button type="submit" class="bg-gray-800 hover:bg-gray-900 text-white font-semibold py-2 px-3 rounded text-xs">
                                        Update
                                    </button>
                                </form>
                            </div>
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
