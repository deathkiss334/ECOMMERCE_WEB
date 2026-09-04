<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Merchant Portal &bull; Order Fulfillment</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        brand: '#E8411E',
                        'brand-dark': '#C23616',
                    }
                }
            }
        }
    </script>
</head>
<body class="bg-slate-100 text-slate-800 antialiased min-h-screen flex flex-col">
    <!-- Top Nav -->
    <header class="bg-white border-b border-slate-200 sticky top-0 z-30 shadow-sm">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
            <div class="flex items-center space-x-3">
                <div class="w-10 h-10 rounded-xl bg-brand flex items-center justify-center text-white font-black text-lg shadow-md shadow-brand/30">
                    <i class="fa-solid fa-utensils"></i>
                </div>
                <div>
                    <h1 class="font-bold text-lg text-slate-900 leading-tight">E-Commerce Admin Portal</h1>
                    <p class="text-xs text-slate-500 font-medium">Order Fulfillment & Operations Dashboard</p>
                </div>
            </div>

            <div class="flex items-center space-x-4">
                <a href="/admin/orders" class="text-sm font-semibold text-brand px-3 py-1.5 rounded-lg bg-brand/10 hover:bg-brand/20 transition">
                    <i class="fa-solid fa-boxes-packing mr-1"></i> Orders
                </a>
                <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">
                    <span class="w-2 h-2 mr-1.5 bg-emerald-500 rounded-full animate-pulse"></span> Live Store Online
                </span>
            </div>
        </div>
    </header>

    <!-- Main Container -->
    <main class="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8">
        @if(session('success'))
            <div class="mb-6 p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 flex items-center shadow-sm">
                <i class="fa-solid fa-circle-check text-emerald-500 text-lg mr-3"></i>
                <span class="font-medium text-sm">{{ session('success') }}</span>
            </div>
        @endif

        @yield('content')
    </main>

    <!-- Footer -->
    <footer class="bg-white border-t border-slate-200 py-4 text-center text-xs text-slate-500">
        E-Commerce Operations &bull; Aligned with Presentation Defense Standards &bull; Laravel Backend & Flutter Client
    </footer>
</body>
</html>
