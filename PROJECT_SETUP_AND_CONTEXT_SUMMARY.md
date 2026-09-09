# 📋 E-Commerce Platform: Complete Setup & Context Summary
*Current Status: Fully Operational Hybrid Architecture (Laravel 11 + SQLite + Firebase Firestore + Flutter Mobile)*

---

## 1. Executive Summary & Current State
The project has evolved from a standalone, static Flutter mobile UI into a **production-grade, multi-tier Hybrid E-Commerce Platform**. 

It specifically bridges two critical requirements:
1. **Academic Presentation Rubric (Score 5/5 Target)**: Requires server-authoritative price integrity, PCI-defensive checkout flows, PayMongo E-wallet gateway handling, store-owner dispatch operations with strict SLAs, and customer retention/review mechanics.
2. **Database Requirement**: Incorporates **Firebase Cloud Firestore** for real-time cloud synchronization without sacrificing SQL relational transaction security.

---

## 2. Architecture & Data Pipeline (The "Hybrid" Setup)

```
                       ┌───────────────────────────────────────┐
                       │          FLUTTER MOBILE APP           │
                       │   • Android Emulator (emulator-5554)  │
                       │   • Material 3 Brand Theme (#E8411E)  │
                       └───────────────────▲───────────────────┘
                                           │
                        (1) POST /api/checkout (Item IDs & Qty only)
                        (4) Real-Time Order Stream & Polling
                                           │
                       ┌───────────────────┴───────────────────┐
                       │         LARAVEL 11 BACKEND            │
                       │   • REST API (:8000/api)              │
                       │   • Admin Portal (:8000/admin/orders) │
                       │   • OpenSSL JWT Google Auth Engine    │
                       └───────────┬───────────────────────┬───┘
                                   │                       │
               (2) ACID Atomic Tx  │                       │ (3) Real-Time Sync
                                   ▼                       ▼
      ┌──────────────────────────────┐   ┌────────────────────────────────┐
      │     CENTRAL SQLITE DB        │   │    FIREBASE CLOUD FIRESTORE    │
      │ • Products & Multi-Variants  │   │ • Project: e-commerce-72e39    │
      │ • Immutable Order Snapshots  │   │ • Collection: 'orders'         │
      │ • Payments Ledger (UUIDs)    │   │ • Real-time cloud documents    │
      └──────────────────────────────┘   └────────────────────────────────┘
```

### Why this Hybrid pattern works:
* **Anti-Tampering Security**: The Flutter app never calculates prices or sends currency totals to the backend. It only sends variant IDs and quantities. Laravel queries the database, computes authentic prices, snapshots the invoice, and creates the order atomically.
* **Live Cloud Sync**: As soon as Laravel writes the order (or updates its status in the Admin dashboard), `FirebaseService.php` generates an OAuth2 JWT token and updates Google Cloud Firestore via REST API with zero native compilation overhead.

---

## 3. Key Credentials & Verified Endpoints

| Service / Resource | Location / Detail | Verification Status |
| :--- | :--- | :--- |
| **Firebase Project ID** | `e-commerce-72e39` | ✅ Verified Active |
| **Firestore Database** | Asia-Southeast1 (Singapore / Test Mode) | ✅ Verified (Collection: `orders`) |
| **Firebase Service Account** | `ecommerce_backend/storage/app/firebase/service-account.json` | ✅ Installed & `.gitignore` protected |
| **Laravel Backend Server** | `http://127.0.0.1:8000` | ✅ Operational |
| **Admin Operations Portal** | `http://localhost:8000/admin/orders` | ✅ Operational |
| **Flutter Emulator Host IP** | `http://10.0.2.2:8000/api` | ✅ Built into `ApiService.dart` |

---

## 4. Key Accomplishments Across Project Phases

### ✅ Phase 1: Database & Inventory Foundation
* 12 relational migration tables (`products`, `product_variants`, `orders`, `order_items`, `payments`, etc.).
* Multi-variant design (e.g., Ube Milk Tea Regular vs. Large) with SKU tagging.
* Historical snapshot protection in `order_items`.

### ✅ Phase 2: Core Frontend Integration
* **Adapter Pattern** ([adapter_service.dart](file:///home/rexsm/Projects/Code/E-commerce/ECOMMERCE_MOBILE/ecommerce_frontend/lib/services/adapter_service.dart)) converts backend relational JSON into the UI models without breaking existing visual widgets.
* Dynamic loading spinner overlay during cold boots.

### ✅ Phase 3: Checkout & PayMongo Engine
* Defensive `POST /api/checkout` endpoint.
* E-wallet (GCash / Maya) deep-linking via `url_launcher`.
* Webhook listener ([WebhookController.php](file:///home/rexsm/Projects/Code/E-commerce/ECOMMERCE_MOBILE/ecommerce_backend/app/Http/Controllers/Api/WebhookController.php)) that updates order and payment ledgers upon remote payment completion.

### ✅ Phase 4: Store Fulfillment Web Portal
* Responsive Tailwind dashboard at `http://localhost:8000/admin/orders`.
* Live business counters (Total Orders, Kitchen Prep Queue, Dispatched, Delivered, Gross Revenue).
* Operational SLAs directly embedded: Confirmation (<10m), Prep (<24h), Dispatch, Refund (<2 days).
* One-click fulfillment advancement buttons (`Prepare` ➔ `Dispatch` ➔ `Complete`).

### ✅ Phase 5: Customer Retention & Real-Time Tracking
* Interactive 4-step progress tracker in Flutter:
  $$\text{Confirmed} \longrightarrow \text{Packing} \longrightarrow \text{On Delivery 🛵} \longrightarrow \text{Delivered 🎉}$$
* Post-delivery 5-star customer review mechanism.

### ✅ Phase 6: Real-Time Firebase Cloud Sync
* Built native JWT OAuth2 Google API service in [FirebaseService.php](file:///home/rexsm/Projects/Code/E-commerce/ECOMMERCE_MOBILE/ecommerce_backend/app/Services/FirebaseService.php).
* Orders automatically mirror to Cloud Firestore in real time.
* Verified documents `ORD-DEMO001` and `ORD-DEMO002` live in the Firebase Console.

---

## 5. Important Project Conventions & Context

1. **PHP Environment Note**:
   The Linux system PHP setup is missing `ext-iconv`. If running Composer commands, always append:
   ```bash
   composer require <package> --ignore-platform-req=ext-iconv
   ```
2. **No XAMPP Needed**:
   Laravel uses SQLite and its built-in PHP development server. Never launch Apache or MySQL from XAMPP, as this wastes system memory needed by the Android Emulator.
3. **Emulator Networking**:
   The Android emulator accesses your computer's `127.0.0.1` via the special gateway IP **`10.0.2.2`**. This is already configured in [api_service.dart](file:///home/rexsm/Projects/Code/E-commerce/ECOMMERCE_MOBILE/ecommerce_frontend/lib/services/api_service.dart).
4. **Git Workspace Structure**:
   * Root: `/home/rexsm/Projects/Code/E-commerce`
   * Mobile Branch Worktree: `ECOMMERCE_MOBILE` (branch: `master-mobile`)
   * Web Branch Worktree: `ECOMMERCE_WEB` (branch: `master`)
   * All sensitive keys (`service-account.json`, `.env`) are strictly ignored by `.gitignore`.

---

## 6. How to Run & Demonstrate the Complete Project

```bash
# TERMINAL 1: Backend Server
cd /home/rexsm/Projects/Code/E-commerce/ECOMMERCE_MOBILE/ecommerce_backend
php artisan serve --host=127.0.0.1 --port=8000

# TERMINAL 2: Flutter App on Android Emulator
cd /home/rexsm/Projects/Code/E-commerce/ECOMMERCE_MOBILE/ecommerce_frontend
flutter run -d emulator-5554

# BROWSER: Open the Merchant Admin Portal
http://localhost:8000/admin/orders

# BROWSER: Open Firebase Console to view live Firestore documents
https://console.firebase.google.com/project/e-commerce-72e39/firestore
```
