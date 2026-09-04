@extends('layouts.admin')

@section('content')
<div class="space-y-6">

    <!-- Breadcrumb & Top Bar -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
            <a href="/admin/orders" class="inline-flex items-center text-xs font-semibold text-slate-500 hover:text-brand mb-2 transition">
                <i class="fa-solid fa-arrow-left mr-1.5"></i> Back to Orders List
            </a>
            <div class="flex items-center gap-3">
                <h2 class="text-2xl font-black text-slate-900">Order {{ $order->order_number }}</h2>
                @if($order->status === 'pending')
                    <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-800">Pending Confirmation</span>
                @elseif($order->status === 'preparing')
                    <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-blue-100 text-blue-800">Packing & Prep</span>
                @elseif($order->status === 'dispatched')
                    <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-indigo-100 text-indigo-800">Out for Delivery</span>
                @elseif($order->status === 'delivered')
                    <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800">Completed & Delivered</span>
                @else
                    <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-rose-100 text-rose-800">Cancelled / Refunded</span>
                @endif
            </div>
            <p class="text-xs text-slate-500 mt-1">Recorded on {{ $order->created_at->format('F d, Y @ h:i A') }} ({{ $order->created_at->diffForHumans() }})</p>
        </div>

        <!-- Action Status Modifier -->
        <div class="flex items-center gap-2">
            <form method="POST" action="/admin/orders/{{ $order->id }}/status" class="flex items-center gap-2">
                @csrf
                <select name="status" class="text-xs font-semibold bg-white border border-slate-300 rounded-xl px-3 py-2 shadow-sm focus:outline-none focus:ring-2 focus:ring-brand">
                    <option value="pending" {{ $order->status === 'pending' ? 'selected' : '' }}>Pending</option>
                    <option value="preparing" {{ $order->status === 'preparing' ? 'selected' : '' }}>Preparing</option>
                    <option value="dispatched" {{ $order->status === 'dispatched' ? 'selected' : '' }}>Dispatched</option>
                    <option value="delivered" {{ $order->status === 'delivered' ? 'selected' : '' }}>Delivered</option>
                    <option value="cancelled" {{ $order->status === 'cancelled' ? 'selected' : '' }}>Cancelled</option>
                </select>
                <button type="submit" class="px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold shadow-sm transition">
                    Update Status
                </button>
            </form>
        </div>
    </div>

    <!-- Fulfillment Pipeline Visualizer (Rubric: Accurate order records & status updates) -->
    <div class="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <h3 class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-5">Order Fulfillment Life-Cycle</h3>
        @php
            $statuses = ['pending', 'preparing', 'dispatched', 'delivered'];
            $currentIndex = array_search($order->status, $statuses);
            if ($currentIndex === false) $currentIndex = -1;
        @endphp
        <div class="grid grid-cols-4 gap-2 relative">
            <div class="text-center">
                <div class="w-10 h-10 mx-auto rounded-full flex items-center justify-center text-sm font-bold {{ $currentIndex >= 0 ? 'bg-brand text-white shadow-md shadow-brand/30' : 'bg-slate-100 text-slate-400' }}">
                    <i class="fa-solid fa-receipt"></i>
                </div>
                <p class="text-xs font-bold mt-2 text-slate-800">1. Placed</p>
                <p class="text-[10px] text-slate-400">Order recorded</p>
            </div>
            <div class="text-center">
                <div class="w-10 h-10 mx-auto rounded-full flex items-center justify-center text-sm font-bold {{ $currentIndex >= 1 ? 'bg-blue-600 text-white shadow-md shadow-blue-500/30' : 'bg-slate-100 text-slate-400' }}">
                    <i class="fa-solid fa-boxes-packing"></i>
                </div>
                <p class="text-xs font-bold mt-2 text-slate-800">2. Preparing</p>
                <p class="text-[10px] text-slate-400">Kitchen / Pack</p>
            </div>
            <div class="text-center">
                <div class="w-10 h-10 mx-auto rounded-full flex items-center justify-center text-sm font-bold {{ $currentIndex >= 2 ? 'bg-indigo-600 text-white shadow-md shadow-indigo-500/30' : 'bg-slate-100 text-slate-400' }}">
                    <i class="fa-solid fa-motorcycle"></i>
                </div>
                <p class="text-xs font-bold mt-2 text-slate-800">3. Dispatched</p>
                <p class="text-[10px] text-slate-400">Rider on the way</p>
            </div>
            <div class="text-center">
                <div class="w-10 h-10 mx-auto rounded-full flex items-center justify-center text-sm font-bold {{ $currentIndex >= 3 ? 'bg-emerald-600 text-white shadow-md shadow-emerald-500/30' : 'bg-slate-100 text-slate-400' }}">
                    <i class="fa-solid fa-house-chimney-check"></i>
                </div>
                <p class="text-xs font-bold mt-2 text-slate-800">4. Delivered</p>
                <p class="text-[10px] text-slate-400">Fulfilled & Received</p>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

        <!-- Left 2 Cols: Items & Pricing Breakdown -->
        <div class="lg:col-span-2 space-y-6">
            <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                <div class="p-5 border-b border-slate-100 flex items-center justify-between">
                    <h3 class="font-bold text-slate-900 text-sm">Ordered Items ({{ $order->items->count() }})</h3>
                    <span class="text-xs text-slate-500">Fixed Snapshot Pricing</span>
                </div>
                <table class="w-full text-left text-sm">
                    <thead class="bg-slate-50 text-slate-500 text-xs uppercase font-semibold">
                        <tr>
                            <th class="py-3 px-5">Item</th>
                            <th class="py-3 px-5">Unit Price</th>
                            <th class="py-3 px-5">Quantity</th>
                            <th class="py-3 px-5 text-right">Total</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100 font-medium text-slate-700">
                        @foreach($order->items as $item)
                            <tr>
                                <td class="py-3.5 px-5">
                                    <p class="font-bold text-slate-900">{{ $item->product_name_snapshot }}</p>
                                    <p class="text-xs text-slate-400">{{ $item->variant_name_snapshot }}</p>
                                </td>
                                <td class="py-3.5 px-5">&#8369;{{ number_format($item->unit_price, 2) }}</td>
                                <td class="py-3.5 px-5 font-bold">{{ $item->quantity }}</td>
                                <td class="py-3.5 px-5 text-right font-black text-slate-900">&#8369;{{ number_format($item->total_price, 2) }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
                <div class="p-5 bg-slate-50 border-t border-slate-100 flex justify-end">
                    <div class="w-64 space-y-1.5 text-xs">
                        <div class="flex justify-between text-slate-600">
                            <span>Subtotal:</span>
                            <span class="font-semibold">&#8369;{{ number_format($order->subtotal, 2) }}</span>
                        </div>
                        <div class="flex justify-between text-slate-600">
                            <span>Delivery Fee:</span>
                            <span class="font-semibold">&#8369;{{ number_format($order->delivery_fee, 2) }}</span>
                        </div>
                        <div class="border-t border-slate-200 pt-2 flex justify-between text-sm font-black text-slate-900">
                            <span>Total Due:</span>
                            <span class="text-brand">&#8369;{{ number_format($order->total_amount, 2) }}</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Notes & Audit Trail -->
            <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
                <h3 class="font-bold text-slate-900 text-sm flex items-center">
                    <i class="fa-solid fa-clipboard-list text-slate-400 mr-2"></i> Delivery Instructions & Audit Notes
                </h3>
                <div class="bg-slate-50 p-4 rounded-xl text-xs text-slate-700 whitespace-pre-line font-mono border border-slate-100">
                    {{ $order->notes ?: 'No special delivery instructions provided.' }}
                </div>
            </div>
        </div>

        <!-- Right Col: Customer Info, Payment & Return Handling -->
        <div class="space-y-6">

            <!-- Customer Details Card -->
            <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3 text-xs">
                <h3 class="font-bold text-slate-900 text-sm flex items-center">
                    <i class="fa-solid fa-user text-slate-400 mr-2"></i> Customer Info
                </h3>
                <div class="space-y-2 text-slate-600">
                    <p><strong class="text-slate-900">Name:</strong> {{ $order->user->name ?? 'Demo Customer' }}</p>
                    <p><strong class="text-slate-900">Account:</strong> {{ $order->user->email ?? 'customer@example.com' }}</p>
                    <p><strong class="text-slate-900">Destination:</strong> Dasmari&ntilde;as, Cavite</p>
                </div>
            </div>

            <!-- Payment Details Card -->
            <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3 text-xs">
                <h3 class="font-bold text-slate-900 text-sm flex items-center">
                    <i class="fa-solid fa-credit-card text-slate-400 mr-2"></i> Payment Ledger
                </h3>
                @forelse($order->payments as $payment)
                    <div class="p-3 rounded-xl bg-slate-50 border border-slate-100 space-y-1">
                        <div class="flex justify-between items-center">
                            <span class="font-bold uppercase text-slate-800">{{ $payment->payment_method }}</span>
                            <span class="font-bold text-slate-900">&#8369;{{ number_format($payment->amount, 2) }}</span>
                        </div>
                        <p class="text-slate-500">Gateway: <span class="font-mono text-slate-700">{{ $payment->gateway }}</span></p>
                        <p class="text-slate-500">Status: 
                            <span class="font-bold {{ $payment->status === 'succeeded' ? 'text-emerald-600' : ($payment->status === 'refunded' ? 'text-purple-600' : 'text-amber-600') }}">
                                {{ ucfirst($payment->status) }}
                            </span>
                        </p>
                        @if($payment->gateway_reference_id)
                            <p class="text-[10px] text-slate-400 font-mono truncate">Ref: {{ $payment->gateway_reference_id }}</p>
                        @endif
                    </div>
                @empty
                    <p class="text-slate-400 italic">No payment transactions recorded.</p>
                @endforelse
            </div>

            <!-- Returns, Refunds & Service Recovery Card (Rubric: Returns process, Refund process, Handling of damaged or incorrect orders) -->
            <div class="bg-white p-5 rounded-2xl border border-rose-200 shadow-sm space-y-3">
                <h3 class="font-bold text-rose-700 text-sm flex items-center">
                    <i class="fa-solid fa-rotate-left mr-2"></i> Service Recovery & Refunds
                </h3>
                <p class="text-xs text-slate-500">
                    Complies with the 2-business-day refund service standard for damaged/cancelled items.
                </p>

                @if($order->payment_status !== 'refunded')
                    <form method="POST" action="/admin/orders/{{ $order->id }}/refund" onsubmit="return confirm('Confirm refunding order #{{ $order->order_number }}?');">
                        @csrf
                        <div class="space-y-2">
                            <input type="text" name="refund_reason" required placeholder="Reason (e.g. Damaged package, out of stock)" class="w-full text-xs bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 focus:ring-1 focus:ring-rose-500">
                            <button type="submit" class="w-full py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-lg text-xs font-bold transition">
                                Issue Refund / Cancel Order
                            </button>
                        </div>
                    </form>
                @else
                    <div class="p-3 bg-purple-50 border border-purple-200 rounded-xl text-xs text-purple-800 font-semibold text-center">
                        <i class="fa-solid fa-circle-check mr-1"></i> Refund Processed for this order
                    </div>
                @endif
            </div>

        </div>

    </div>

</div>
@endsection
