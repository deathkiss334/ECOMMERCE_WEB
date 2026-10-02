<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Store Dashboard - Order Management | DasmaBITES</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Plus Jakarta Sans', sans-serif; }
        @keyframes pulse-subtle {
            0%, 100% { opacity: 1; transform: scale(1); }
            50% { opacity: 0.85; transform: scale(1.02); }
        }
        .pulse-active { animation: pulse-subtle 2s infinite ease-in-out; }
    </style>
</head>
<body class="bg-slate-50 text-slate-800 antialiased min-h-screen flex flex-col">
    <!-- Top Navbar -->
    <nav class="bg-[#E8411E] text-white shadow-lg sticky top-0 z-30">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-3.5 flex justify-between items-center">
            <div class="flex items-center gap-3">
                <span class="text-2xl">🍔</span>
                <div>
                    <h1 class="text-lg font-extrabold tracking-tight">DasmaBITES Order Management</h1>
                    <p class="text-xs text-orange-100 font-medium">Real-Time Kitchen, Delivery & GCash Verification Pipeline</p>
                </div>
            </div>
            <div class="flex items-center gap-3">
                <a href="/db-viewer" target="_blank" class="text-xs bg-orange-700/60 hover:bg-orange-800/80 px-3 py-1.5 rounded-lg border border-orange-400/30 flex items-center gap-1.5 transition">
                    <span>🗄️</span> SQLite DB Viewer
                </a>
                <a href="/admin/orders" class="text-xs bg-white text-[#E8411E] font-bold px-3 py-1.5 rounded-lg shadow-sm hover:bg-orange-50 transition flex items-center gap-1.5">
                    <span>🔄</span> Refresh
                </a>
                <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-500/20 text-emerald-100 border border-emerald-400/40">
                    <span class="w-2 h-2 rounded-full bg-emerald-400 animate-ping"></span> Live Kitchen
                </span>
            </div>
        </div>
    </nav>

    <!-- Main Container -->
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 flex-1 w-full">
        @if(session('success'))
            <div class="mb-6 p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 flex items-center justify-between shadow-sm">
                <div class="flex items-center gap-3">
                    <span class="text-xl">✅</span>
                    <span class="font-medium text-sm">{{ session('success') }}</span>
                </div>
                <button onclick="this.parentElement.remove()" class="text-emerald-500 hover:text-emerald-800 font-bold">&times;</button>
            </div>
        @endif

        @if(session('error'))
            <div class="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 text-red-800 flex items-center justify-between shadow-sm">
                <div class="flex items-center gap-3">
                    <span class="text-xl">⚠️</span>
                    <span class="font-medium text-sm">{{ session('error') }}</span>
                </div>
                <button onclick="this.parentElement.remove()" class="text-red-500 hover:text-red-800 font-bold">&times;</button>
            </div>
        @endif

        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
            <div>
                <h2 class="text-2xl font-black text-slate-900 tracking-tight">Active Orders Pipeline</h2>
                <p class="text-xs text-slate-500 mt-0.5">Click any card to launch the live Customer Chat Drawer</p>
            </div>
            <div class="flex items-center gap-2">
                <span class="text-xs font-semibold px-3 py-1.5 bg-slate-200/80 rounded-lg text-slate-700">
                    Total: <strong class="text-slate-900">{{ count($orders) }}</strong> Orders
                </span>
            </div>
        </div>

        @if($orders->isEmpty())
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-12 text-center">
                <span class="text-5xl block mb-3">🛵</span>
                <h3 class="text-lg font-bold text-slate-800">No Orders in the System Yet</h3>
                <p class="text-sm text-slate-500 mt-1 max-w-md mx-auto">
                    Place a test order via the customer checkout or mobile app to watch the live sequential lifecycle in action.
                </p>
            </div>
        @else
            <div class="space-y-6">
                @foreach($orders as $order)
                    @php
                        $st = strtoupper($order->status);
                        // Map status to 1-5 pipeline stage
                        $currentStep = 1;
                        if (in_array($st, ['PREPARING'])) {
                            $currentStep = 2;
                        } elseif (in_array($st, ['OUT_FOR_DELIVERY', 'DISPATCHED'])) {
                            $currentStep = 3;
                        } elseif (in_array($st, ['RIDER_ARRIVED'])) {
                            $currentStep = 4;
                        } elseif (in_array($st, ['DELIVERED', 'COMPLETED'])) {
                            $currentStep = 5;
                        }

                        $isDelivery = strtoupper($order->order_type ?? 'DELIVERY') !== 'DINE_IN' && strtoupper($order->order_type ?? 'DELIVERY') !== 'PICKUP';
                        $receiptUrl = $order->receipt_image_url ?? $order->gcash_receipt_path ?? null;
                        if ($receiptUrl && !str_starts_with($receiptUrl, 'http') && !str_starts_with($receiptUrl, '/')) {
                            $receiptUrl = '/' . $receiptUrl;
                        }
                        $refNo = $order->gcash_ref_number ?? $order->gcash_reference_no ?? ($order->latestPayment->gateway_reference_id ?? null);
                        $customerName = $order->customer_name ?: ($order->customer->name ?? 'Guest Customer');
                    @endphp

                    <div class="bg-white rounded-2xl border border-slate-200/90 shadow-sm hover:shadow-md transition duration-200 overflow-hidden" id="order-card-{{ $order->id }}">
                        <!-- Card Header -->
                        <div class="px-6 py-4 bg-slate-50/80 border-b border-slate-200/80 flex flex-wrap items-center justify-between gap-3">
                            <div class="flex items-center gap-3">
                                <span class="font-extrabold text-base text-slate-900 tracking-tight">#{{ $order->order_number }}</span>
                                <span class="text-xs text-slate-500 font-medium">🕒 {{ $order->created_at ? $order->created_at->diffForHumans() : 'Just now' }}</span>
                                
                                @if($isDelivery)
                                    <span class="px-2.5 py-0.5 rounded-full text-xs font-bold bg-blue-50 text-blue-700 border border-blue-200/60 flex items-center gap-1">
                                        🛵 Delivery
                                    </span>
                                @else
                                    <span class="px-2.5 py-0.5 rounded-full text-xs font-bold bg-purple-50 text-purple-700 border border-purple-200/60 flex items-center gap-1">
                                        🛍️ Pick-up / Dine-in
                                    </span>
                                @endif

                                @if($order->payment_status === 'paid')
                                    <span class="px-2.5 py-0.5 rounded-full text-xs font-extrabold bg-emerald-100 text-emerald-800 border border-emerald-300">
                                        ✓ PAID
                                    </span>
                                @elseif($order->payment_status === 'awaiting_verification' || $st === 'AWAITING_VERIFICATION')
                                    <span class="px-2.5 py-0.5 rounded-full text-xs font-extrabold bg-amber-100 text-amber-800 border border-amber-300 pulse-active">
                                        🔍 VERIFY GCASH
                                    </span>
                                @elseif($order->payment_status === 'rejected')
                                    <span class="px-2.5 py-0.5 rounded-full text-xs font-bold bg-red-100 text-red-800 border border-red-300">
                                        ❌ RECEIPT REJECTED
                                    </span>
                                @else
                                    <span class="px-2.5 py-0.5 rounded-full text-xs font-bold bg-slate-100 text-slate-700 border border-slate-300">
                                        ⏳ UNPAID
                                    </span>
                                @endif
                            </div>

                            <!-- Live Chat Drawer Opener Button -->
                            <button onclick="openChatDrawer('{{ $order->order_number }}', '{{ addslashes($customerName) }}', '{{ $st }}')"
                                    class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-900 hover:bg-[#E8411E] text-white text-xs font-bold transition shadow-sm">
                                <span>💬</span> Chat with Customer
                                @if($order->chats && $order->chats->count() > 0)
                                    <span class="bg-white/20 px-1.5 py-0.2 rounded-full text-[10px]">{{ $order->chats->count() }}</span>
                                @endif
                            </button>
                        </div>

                        <!-- Card Body -->
                        <div class="p-6">
                            <!-- Visual Horizontal Stepper -->
                            <div class="mb-6 bg-slate-50 p-4 rounded-xl border border-slate-100">
                                <div class="flex items-center justify-between relative">
                                    <!-- Background Bar -->
                                    <div class="absolute left-6 right-6 top-1/2 -translate-y-1/2 h-1 bg-slate-200 z-0"></div>
                                    <!-- Active Progress Bar -->
                                    @php
                                        $progressWidth = match($currentStep) {
                                            1 => '0%',
                                            2 => '25%',
                                            3 => '50%',
                                            4 => '75%',
                                            5 => '100%',
                                            default => '0%'
                                        };
                                    @endphp
                                    <div class="absolute left-6 top-1/2 -translate-y-1/2 h-1 bg-emerald-500 transition-all duration-500 z-0" style="width: {{ $progressWidth }};"></div>

                                    <!-- Step 1: Verification -->
                                    <div class="relative z-10 flex flex-col items-center">
                                        <div class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition {{ $currentStep > 1 ? 'bg-emerald-500 text-white' : ($currentStep === 1 ? 'bg-[#E8411E] text-white ring-4 ring-orange-200 pulse-active' : 'bg-slate-200 text-slate-600') }}">
                                            {!! $currentStep > 1 ? '✓' : '1' !!}
                                        </div>
                                        <span class="text-[11px] font-bold mt-1.5 {{ $currentStep === 1 ? 'text-[#E8411E]' : 'text-slate-600' }}">Verification</span>
                                    </div>

                                    <!-- Step 2: Kitchen Preparing -->
                                    <div class="relative z-10 flex flex-col items-center">
                                        <div class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition {{ $currentStep > 2 ? 'bg-emerald-500 text-white' : ($currentStep === 2 ? 'bg-[#E8411E] text-white ring-4 ring-orange-200 pulse-active' : 'bg-slate-200 text-slate-600') }}">
                                            {!! $currentStep > 2 ? '✓' : '2' !!}
                                        </div>
                                        <span class="text-[11px] font-bold mt-1.5 {{ $currentStep === 2 ? 'text-[#E8411E]' : 'text-slate-600' }}">Kitchen</span>
                                    </div>

                                    <!-- Step 3: Out for Delivery -->
                                    <div class="relative z-10 flex flex-col items-center">
                                        <div class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition {{ $currentStep > 3 ? 'bg-emerald-500 text-white' : ($currentStep === 3 ? 'bg-[#E8411E] text-white ring-4 ring-orange-200 pulse-active' : 'bg-slate-200 text-slate-600') }}">
                                            {!! $currentStep > 3 ? '✓' : '3' !!}
                                        </div>
                                        <span class="text-[11px] font-bold mt-1.5 {{ $currentStep === 3 ? 'text-[#E8411E]' : 'text-slate-600' }}">On The Way</span>
                                    </div>

                                    <!-- Step 4: Rider Arrived -->
                                    <div class="relative z-10 flex flex-col items-center">
                                        <div class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition {{ $currentStep > 4 ? 'bg-emerald-500 text-white' : ($currentStep === 4 ? 'bg-emerald-600 text-white ring-4 ring-emerald-200 pulse-active' : 'bg-slate-200 text-slate-600') }}">
                                            {!! $currentStep > 4 ? '✓' : '4' !!}
                                        </div>
                                        <span class="text-[11px] font-bold mt-1.5 {{ $currentStep === 4 ? 'text-emerald-700 font-extrabold' : 'text-slate-600' }}">Rider Arrived</span>
                                    </div>

                                    <!-- Step 5: Completed -->
                                    <div class="relative z-10 flex flex-col items-center">
                                        <div class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition {{ $currentStep === 5 ? 'bg-emerald-600 text-white ring-4 ring-emerald-200' : 'bg-slate-200 text-slate-600' }}">
                                            {!! $currentStep === 5 ? '✓' : '5' !!}
                                        </div>
                                        <span class="text-[11px] font-bold mt-1.5 {{ $currentStep === 5 ? 'text-emerald-700 font-extrabold' : 'text-slate-600' }}">Delivered</span>
                                    </div>
                                </div>

                                <!-- High-Contrast Rider Arrived Banner if at stage 4 -->
                                @if($currentStep === 4)
                                    <div class="mt-4 p-3 bg-emerald-500 text-white font-extrabold rounded-lg flex items-center justify-center gap-2 text-xs shadow animate-bounce">
                                        <span>🛵📍</span> RIDER HAS ARRIVED AT CUSTOMER LOCATION! PLEASE CONFIRM HAND-OFF.
                                    </div>
                                @endif
                            </div>

                            <!-- Details Grid -->
                            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                                <!-- Col 1: Customer & Address -->
                                <div class="space-y-2">
                                    <h4 class="text-xs font-bold text-slate-400 uppercase tracking-wider">Customer & Location</h4>
                                    <p class="font-bold text-slate-800 text-sm flex items-center gap-1.5">
                                        <span>👤</span> {{ $customerName }}
                                    </p>
                                    @if($order->customer_email)
                                        <p class="text-xs text-slate-500">{{ $order->customer_email }}</p>
                                    @endif
                                    <p class="text-xs text-slate-600 bg-slate-50 p-2.5 rounded-lg border border-slate-200/80">
                                        <strong>Destination:</strong> {{ $order->notes ?: 'Dine-In / Counter Pickup' }}
                                    </p>
                                    <p class="text-xs text-slate-500">
                                        Method: <strong class="uppercase text-slate-700">{{ $order->latestPayment->payment_method ?? 'GCash' }}</strong>
                                    </p>
                                </div>

                                <!-- Col 2: Items & Total -->
                                <div class="space-y-2">
                                    <h4 class="text-xs font-bold text-slate-400 uppercase tracking-wider">Items Ordered</h4>
                                    <ul class="text-xs text-slate-700 space-y-1 max-h-32 overflow-y-auto">
                                        @foreach($order->items as $item)
                                            <li class="flex justify-between items-center py-0.5 border-b border-slate-100">
                                                <span>{{ $item->quantity }}x {{ $item->product_name_snapshot }}</span>
                                                <span class="font-semibold text-slate-800">₱{{ number_format($item->total_price, 2) }}</span>
                                            </li>
                                        @endforeach
                                    </ul>
                                    <div class="pt-2 flex justify-between items-center text-sm border-t border-slate-200">
                                        <span class="font-bold text-slate-600">Total Amount:</span>
                                        <span class="font-extrabold text-base text-[#E8411E]">₱{{ number_format($order->total_amount, 2) }}</span>
                                    </div>
                                </div>

                                <!-- Col 3: Receipt & Tracking -->
                                <div class="space-y-3">
                                    <h4 class="text-xs font-bold text-slate-400 uppercase tracking-wider">GCash Verification & Tracking</h4>
                                    
                                    <!-- Receipt Trigger & Reference -->
                                    <div class="bg-slate-50 p-3 rounded-xl border border-slate-200/80 space-y-2">
                                        <div class="flex items-center justify-between text-xs">
                                            <span class="text-slate-500">GCash Ref:</span>
                                            <strong class="font-mono text-slate-900 bg-white px-2 py-0.5 rounded border border-slate-200">
                                                {{ $refNo ?: 'Not Provided' }}
                                            </strong>
                                        </div>

                                        @if($receiptUrl)
                                            <button type="button" 
                                                    onclick="openReceiptModal('{{ $receiptUrl }}', '{{ $refNo }}', '{{ $order->id }}', '{{ $order->order_number }}')"
                                                    class="w-full bg-blue-50 hover:bg-blue-100 text-blue-700 font-bold py-1.5 px-3 rounded-lg text-xs flex items-center justify-center gap-1.5 border border-blue-200 transition">
                                                <span>🧾</span> View GCash Receipt Image
                                            </button>
                                        @else
                                            <div class="text-[11px] text-slate-400 italic text-center py-1">
                                                No receipt image uploaded
                                            </div>
                                        @endif
                                    </div>

                                    <!-- Lalamove Tracking Input -->
                                    @if($isDelivery)
                                        <form action="/admin/orders/{{ $order->id }}/tracking" method="POST" class="space-y-1.5">
                                            @csrf
                                            <label class="text-[11px] font-bold text-slate-600 block">🛵 Lalamove Share Tracking Link:</label>
                                            <div class="flex gap-1.5">
                                                <input type="url" name="lalamove_tracking_url" value="{{ $order->lalamove_tracking_url }}"
                                                       placeholder="https://share.lalamove.com/..." 
                                                       class="w-full text-xs px-2.5 py-1.5 rounded-lg border border-slate-300 focus:outline-none focus:ring-1 focus:ring-blue-500" required>
                                                <button type="submit" class="bg-slate-800 hover:bg-slate-900 text-white font-bold px-3 py-1.5 rounded-lg text-xs transition">
                                                    Save
                                                </button>
                                            </div>
                                        </form>

                                        @if($order->lalamove_tracking_url)
                                            <a href="{{ $order->lalamove_tracking_url }}" target="_blank"
                                               class="w-full bg-orange-50 hover:bg-orange-100 text-[#E8411E] font-bold py-1.5 px-3 rounded-lg text-xs flex items-center justify-center gap-1.5 border border-orange-200 transition">
                                                <span>🛵</span> Open Live Lalamove Tracking ↗
                                            </a>
                                        @endif
                                    @endif
                                </div>
                            </div>

                            <!-- LINEAR SEQUENTIAL ACTION PIPELINE (NO DROPDOWN) -->
                            <div class="mt-6 pt-4 border-t border-slate-200 flex flex-wrap items-center justify-between gap-3">
                                <div class="text-xs text-slate-500">
                                    Current Stage: <span class="font-extrabold text-slate-800">{{ $st ?: 'AWAITING_VERIFICATION' }}</span>
                                </div>

                                <div class="flex flex-wrap items-center gap-2">
                                    <!-- STAGE 1: VERIFICATION ACTIONS -->
                                    @if($currentStep === 1)
                                        <form action="/admin/orders/{{ $order->id }}/verify-payment" method="POST">
                                            @csrf
                                            <button type="submit" class="bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold px-4 py-2 rounded-xl text-xs flex items-center gap-1.5 shadow-sm transition">
                                                <span>✅</span> Approve Payment & Start Preparing
                                            </button>
                                        </form>

                                        <button type="button" 
                                                onclick="openRejectModal('{{ $order->id }}', '{{ $order->order_number }}')"
                                                class="bg-red-50 hover:bg-red-100 text-red-700 font-bold px-3 py-2 rounded-xl text-xs border border-red-200 transition">
                                            <span>❌</span> Reject Receipt
                                        </button>

                                    <!-- STAGE 2: KITCHEN ACTIONS -->
                                    @elseif($currentStep === 2)
                                        <form action="/admin/orders/{{ $order->id }}/status" method="POST" onsubmit="return validateDispatch(this, '{{ $isDelivery ? 1 : 0 }}', '{{ $order->lalamove_tracking_url }}')">
                                            @csrf
                                            <input type="hidden" name="status" value="OUT_FOR_DELIVERY">
                                            <input type="hidden" name="lalamove_tracking_url" id="dispatch-tracking-{{ $order->id }}" value="{{ $order->lalamove_tracking_url }}">
                                            <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white font-extrabold px-4 py-2 rounded-xl text-xs flex items-center gap-1.5 shadow-sm transition">
                                                <span>🛵</span> Dispatch (Out for Delivery)
                                            </button>
                                        </form>

                                    <!-- STAGE 3: OUT FOR DELIVERY ACTIONS -->
                                    @elseif($currentStep === 3)
                                        <form action="/admin/orders/{{ $order->id }}/status" method="POST">
                                            @csrf
                                            <input type="hidden" name="status" value="RIDER_ARRIVED">
                                            <button type="submit" class="bg-purple-600 hover:bg-purple-700 text-white font-extrabold px-4 py-2 rounded-xl text-xs flex items-center gap-1.5 shadow-sm transition">
                                                <span>📍</span> Mark Rider Arrived
                                            </button>
                                        </form>

                                    <!-- STAGE 4: RIDER ARRIVED ACTIONS -->
                                    @elseif($currentStep === 4)
                                        <form action="/admin/orders/{{ $order->id }}/status" method="POST">
                                            @csrf
                                            <input type="hidden" name="status" value="DELIVERED">
                                            <button type="submit" class="bg-emerald-600 hover:bg-emerald-700 text-white font-black px-5 py-2.5 rounded-xl text-xs flex items-center gap-1.5 shadow-md transition">
                                                <span>🎉</span> Confirm Delivered
                                            </button>
                                        </form>

                                    <!-- STAGE 5: COMPLETED (LOCKED) -->
                                    @elseif($currentStep === 5)
                                        <span class="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-slate-100 text-emerald-800 text-xs font-black border border-emerald-300">
                                            <span>✓</span> Order Completed
                                        </span>
                                    @endif
                                </div>
                            </div>
                        </div>
                    </div>
                @endforeach
            </div>
        @endif
    </main>

    <!-- LIVE CUSTOMER-ADMIN CHAT DRAWER -->
    <div id="chat-drawer" class="fixed inset-0 z-50 overflow-hidden hidden" aria-labelledby="slide-over-title" role="dialog" aria-modal="true">
        <!-- Backdrop -->
        <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm transition-opacity" onclick="closeChatDrawer()"></div>

        <div class="pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10">
            <div class="pointer-events-auto w-screen max-w-md bg-white shadow-2xl flex flex-col">
                <!-- Header -->
                <div class="p-4 bg-slate-900 text-white flex items-center justify-between shadow">
                    <div>
                        <h3 class="text-sm font-extrabold flex items-center gap-2">
                            <span>💬</span> Live Customer Chat
                        </h3>
                        <p class="text-xs text-slate-300 font-medium mt-0.5" id="chat-order-title">Order #--- • Customer</p>
                    </div>
                    <button onclick="closeChatDrawer()" class="text-slate-400 hover:text-white font-bold text-xl px-2 py-1 rounded-lg">
                        &times;
                    </button>
                </div>

                <!-- Chat Messages Body -->
                <div id="chat-messages" class="flex-1 p-4 overflow-y-auto space-y-3 bg-slate-50">
                    <div class="text-center py-8 text-xs text-slate-400">Loading conversation...</div>
                </div>

                <!-- Chat Input Form -->
                <form id="chat-send-form" onsubmit="sendChatMessage(event)" class="p-3 bg-white border-t border-slate-200 flex gap-2">
                    <input type="text" id="chat-input-text" placeholder="Type a message to customer..." 
                           class="flex-1 text-xs px-3 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-[#E8411E]" required>
                    <button type="submit" class="bg-[#E8411E] hover:bg-orange-700 text-white font-bold px-4 py-2.5 rounded-xl text-xs shadow transition">
                        Send
                    </button>
                </form>
            </div>
        </div>
    </div>

    <!-- RECEIPT PREVIEW MODAL -->
    <div id="receipt-modal" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm hidden">
        <div class="bg-white rounded-2xl max-w-lg w-full overflow-hidden shadow-2xl border border-slate-200">
            <div class="p-4 bg-slate-900 text-white flex justify-between items-center">
                <div>
                    <h3 class="font-bold text-sm">🧾 GCash Payment Receipt</h3>
                    <p class="text-xs text-slate-300" id="receipt-order-label">Order #---</p>
                </div>
                <button onclick="closeReceiptModal()" class="text-slate-400 hover:text-white text-lg font-bold">&times;</button>
            </div>

            <div class="p-5">
                <div class="mb-3 text-xs bg-slate-100 p-2.5 rounded-lg flex justify-between items-center">
                    <span class="text-slate-500">Reference Number:</span>
                    <strong class="font-mono text-slate-900 text-sm" id="receipt-ref-display">--</strong>
                </div>

                <!-- Image container with fallback -->
                <div class="w-full bg-slate-100 rounded-xl overflow-hidden min-h-[260px] flex items-center justify-center relative border border-slate-200">
                    <img id="receipt-image-elem" src="" alt="Receipt" 
                         class="max-h-[360px] w-auto mx-auto object-contain cursor-pointer"
                         onclick="window.open(this.src, '_blank')"
                         onerror="handleReceiptImgError(this)">
                    
                    <div id="receipt-error-placeholder" class="hidden p-6 text-center">
                        <span class="text-3xl block mb-2">⚠️</span>
                        <p class="text-xs font-bold text-slate-700">Preview Unavailable</p>
                        <p class="text-[11px] text-slate-500 mb-3">The browser was unable to render the image preview directly.</p>
                        <a id="receipt-raw-link" href="#" target="_blank" class="inline-block bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold px-3 py-1.5 rounded-lg">
                            Open Raw File / Download ↗
                        </a>
                    </div>
                </div>
            </div>

            <div class="p-4 bg-slate-50 border-t border-slate-200 flex justify-end gap-2">
                <button onclick="closeReceiptModal()" class="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-200">
                    Close
                </button>
            </div>
        </div>
    </div>

    <!-- REJECT RECEIPT MODAL -->
    <div id="reject-modal" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm hidden">
        <div class="bg-white rounded-2xl max-w-md w-full overflow-hidden shadow-2xl border border-slate-200">
            <form id="reject-form" method="POST" action="">
                @csrf
                <div class="p-4 bg-red-600 text-white flex justify-between items-center">
                    <h3 class="font-bold text-sm">❌ Reject GCash Receipt</h3>
                    <button type="button" onclick="closeRejectModal()" class="text-red-200 hover:text-white text-lg font-bold">&times;</button>
                </div>
                <div class="p-5 space-y-3">
                    <p class="text-xs text-slate-600">
                        Please provide a reason for rejecting this receipt. The customer will be prompted to re-upload.
                    </p>
                    <textarea name="rejection_reason" rows="3" required
                              class="w-full text-xs p-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-red-500"
                              placeholder="e.g. Receipt is blurred or GCash reference number does not match store account."></textarea>
                </div>
                <div class="p-4 bg-slate-50 border-t border-slate-200 flex justify-end gap-2">
                    <button type="button" onclick="closeRejectModal()" class="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-200">Cancel</button>
                    <button type="submit" class="bg-red-600 hover:bg-red-700 text-white font-bold px-4 py-2 rounded-xl text-xs">Confirm Rejection</button>
                </div>
            </form>
        </div>
    </div>

    <!-- JAVASCRIPT LOGIC -->
    <script>
        // ── Receipt Modal Logic ──
        function openReceiptModal(url, ref, orderId, orderNumber) {
            const modal = document.getElementById('receipt-modal');
            const img = document.getElementById('receipt-image-elem');
            const placeholder = document.getElementById('receipt-error-placeholder');
            const rawLink = document.getElementById('receipt-raw-link');
            const refDisplay = document.getElementById('receipt-ref-display');
            const label = document.getElementById('receipt-order-label');

            label.innerText = 'Order #' + orderNumber;
            refDisplay.innerText = ref || 'None';
            rawLink.href = url;
            
            placeholder.classList.add('hidden');
            img.classList.remove('hidden');
            img.src = url;

            modal.classList.remove('hidden');
        }

        function handleReceiptImgError(img) {
            img.classList.add('hidden');
            const placeholder = document.getElementById('receipt-error-placeholder');
            placeholder.classList.remove('hidden');
        }

        function closeReceiptModal() {
            document.getElementById('receipt-modal').classList.add('hidden');
        }

        // ── Reject Modal Logic ──
        function openRejectModal(orderId, orderNumber) {
            const form = document.getElementById('reject-form');
            form.action = '/admin/orders/' + orderId + '/reject-receipt';
            document.getElementById('reject-modal').classList.remove('hidden');
        }

        function closeRejectModal() {
            document.getElementById('reject-modal').classList.add('hidden');
        }

        // ── Dispatch Validation with Lalamove Link prompt ──
        function validateDispatch(form, isDelivery, existingLink) {
            if (isDelivery == 1 && (!existingLink || existingLink.trim() === '')) {
                const link = prompt('Please enter the Lalamove Rider Tracking URL before dispatching:\n(Or leave blank if self-delivering)');
                if (link && link.trim() !== '') {
                    const input = form.querySelector('input[name="lalamove_tracking_url"]');
                    if (input) input.value = link.trim();
                }
            }
            return true;
        }

        // ── Chat Drawer Logic & Polling ──
        let activeChatOrderId = null;
        let chatPollInterval = null;

        function openChatDrawer(orderNumber, customerName, status) {
            activeChatOrderId = orderNumber;
            document.getElementById('chat-order-title').innerText = 'Order #' + orderNumber + ' • ' + customerName + ' (' + status + ')';
            document.getElementById('chat-drawer').classList.remove('hidden');

            fetchChatMessages();
            if (chatPollInterval) clearInterval(chatPollInterval);
            chatPollInterval = setInterval(fetchChatMessages, 3000);
        }

        function closeChatDrawer() {
            document.getElementById('chat-drawer').classList.add('hidden');
            if (chatPollInterval) {
                clearInterval(chatPollInterval);
                chatPollInterval = null;
            }
            activeChatOrderId = null;
        }

        async function fetchChatMessages() {
            if (!activeChatOrderId) return;
            try {
                const res = await fetch('/api/orders/' + activeChatOrderId + '/chat');
                const data = await res.json();
                const container = document.getElementById('chat-messages');

                if (!data.messages || data.messages.length === 0) {
                    container.innerHTML = `
                        <div class="text-center py-12 text-xs text-slate-400">
                            <span>💬</span> No messages yet. Say hello to the customer!
                        </div>
                    `;
                    return;
                }

                container.innerHTML = data.messages.map(m => {
                    const isAdmin = m.sender_role === 'admin' || m.sender_role === 'ADMIN';
                    const time = new Date(m.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
                    
                    if (isAdmin) {
                        return `
                            <div class="flex flex-col items-end">
                                <div class="flex items-center gap-1 text-[10px] text-slate-400 mb-0.5">
                                    <span>🛡️ Store Admin</span> • <span>${time}</span>
                                </div>
                                <div class="bg-[#E8411E] text-white text-xs px-3.5 py-2 rounded-2xl rounded-tr-none max-w-[85%] shadow-sm">
                                    ${m.message}
                                </div>
                            </div>
                        `;
                    } else {
                        return `
                            <div class="flex flex-col items-start">
                                <div class="flex items-center gap-1 text-[10px] text-slate-400 mb-0.5">
                                    <span>👤 ${m.sender_name || 'Customer'}</span> • <span>${time}</span>
                                </div>
                                <div class="bg-white border border-slate-200 text-slate-800 text-xs px-3.5 py-2 rounded-2xl rounded-tl-none max-w-[85%] shadow-sm">
                                    ${m.message}
                                </div>
                            </div>
                        `;
                    }
                }).join('');

                container.scrollTop = container.scrollHeight;
            } catch (err) {
                console.error('Chat poll error:', err);
            }
        }

        async function sendChatMessage(e) {
            e.preventDefault();
            const input = document.getElementById('chat-input-text');
            const text = input.value.trim();
            if (!text || !activeChatOrderId) return;

            try {
                const res = await fetch('/api/orders/' + activeChatOrderId + '/chat', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        message: text,
                        sender_role: 'admin',
                        sender_name: 'Store Manager'
                    })
                });
                input.value = '';
                fetchChatMessages();
            } catch (err) {
                alert('Failed to send message: ' + err.message);
            }
        }
    </script>
</body>
</html>
