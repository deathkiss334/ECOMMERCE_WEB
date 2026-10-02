<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DasmaBITES &bull; Backend API Server</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        brand: '#F36F21',
                    }
                }
            }
        }
    </script>
</head>
<body class="bg-slate-50 text-slate-800 antialiased min-h-screen flex items-center justify-center p-6">
    <div class="max-w-xl w-full bg-white rounded-3xl shadow-xl shadow-slate-200/60 border border-slate-100 p-8 sm:p-10 text-center">
        <!-- Logo / Icon -->
        <div class="w-16 h-16 bg-orange-100 text-brand rounded-2xl mx-auto flex items-center justify-center text-3xl shadow-inner mb-6">
            <i class="fa-solid fa-server"></i>
        </div>

        <h1 class="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
            DasmaBITES API Server
        </h1>
        <p class="text-sm sm:text-base text-slate-500 mt-2">
            Laravel &bull; SQLite Relational Engine
        </p>

        <!-- Status Pill -->
        <div class="inline-flex items-center gap-2 bg-emerald-50 text-emerald-700 font-semibold px-4 py-1.5 rounded-full text-xs mt-4 border border-emerald-200/60">
            <span class="w-2.5 h-2.5 bg-emerald-500 rounded-full animate-ping"></span>
            REST Services Active &amp; Healthy
        </div>

        <!-- Notification Box for Collaborators -->
        <div class="bg-amber-50/80 border border-amber-200/80 rounded-2xl p-5 mt-6 text-left">
            <div class="flex items-start gap-3">
                <i class="fa-solid fa-circle-info text-amber-600 text-lg mt-0.5"></i>
                <div class="text-xs sm:text-sm text-amber-900 leading-relaxed">
                    <span class="font-bold">Notice for Collaborators:</span><br>
                    This is the <span class="font-semibold underline">headless backend server</span> providing API endpoints for authentication, transactions, and live orders.
                </div>
            </div>
        </div>

        <!-- Quick Links to Frontend -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 mt-6">
            <a href="http://localhost:3000/#/admin" target="_blank" class="flex items-center justify-center gap-2 bg-brand text-white font-semibold py-3 px-4 rounded-xl hover:bg-orange-600 transition shadow-md shadow-brand/20 text-sm">
                <i class="fa-solid fa-gauge"></i> Open Flutter Admin
            </a>
            <a href="http://localhost:3000/#/shop" target="_blank" class="flex items-center justify-center gap-2 bg-slate-100 text-slate-700 font-semibold py-3 px-4 rounded-xl hover:bg-slate-200 transition text-sm">
                <i class="fa-solid fa-store"></i> Open Flutter Store
            </a>
        </div>

        <!-- Security & Status Footer -->
        <div class="mt-8 pt-6 border-t border-slate-100 text-xs text-slate-400 flex items-center justify-center gap-2">
            <i class="fa-solid fa-shield-halved text-emerald-500"></i>
            <span>Secured via Laravel Sanctum &bull; CORS Configured</span>
        </div>
    </div>
</body>
</html>
