# 🔥 Firebase + Laravel Hybrid Database Setup Guide

This guide explains how the **Hybrid Database Architecture** works in this project and provides simple, step-by-step instructions for connecting your Firebase project whenever you are ready.

---

## 🏗️ How the Hybrid Architecture Works

```
┌─────────────────────────────────────────────────────────┐
│                     FLUTTER APP                         │
│   • Browses catalog & customizes variants               │
│   • Submits orders to Laravel API                       │
│   • Streams real-time order tracking from Firebase      │
└───────────────────────────▲─────────────────────────────┘
                            │ (1) POST /api/checkout
                            │ (4) Real-Time Order Stream
┌───────────────────────────┴─────────────────────────────┐
│                   LARAVEL BACKEND                       │
│   • Server-side total calculation (Tamper-proof)        │
│   • PayMongo E-Wallet Link generation & Webhooks        │
│   • Store Owner Admin Portal (/admin/orders)            │
└─────────────┬─────────────────────────────┬─────────────┘
              │ (2) ACID Storage            │ (3) Real-Time Sync
              ▼                             ▼
┌───────────────────────────┐ ┌───────────────────────────┐
│      SQLITE DATABASE      │ │     FIREBASE FIRESTORE    │
│  • Immutable order items  │ │  • Live order status      │
│  • Payments ledger (UUID) │ │  • Multi-client syncing   │
│  • Catalog & inventory    │ │  • Instant push updates   │
└───────────────────────────┘ └───────────────────────────┘
```

1. **Flutter Checkout**: The customer checks out. Flutter sends only item IDs and quantities to Laravel.
2. **Authoritative SQL Ledger**: Laravel computes the true prices, writes to the SQLite database, and creates the order.
3. **Automatic Firebase Sync**: `FirebaseService::syncOrder($order)` automatically serializes the order and synchronizes it to Firebase Cloud Firestore in real time.
4. **Admin Updates**: Whenever the merchant updates an order status in `/admin/orders` (`Preparing` ➔ `Dispatched` ➔ `Completed`), Laravel immediately updates the document in Firebase.
5. **Real-Time Client Updates**: The Flutter app streams live status updates directly from Firebase.

> [!NOTE]
> **Zero Downtime Fallback**: If Firebase credentials are not yet configured, the app operates gracefully using the Laravel REST API without throwing errors or crashing.

---

## 📦 `product_table` Cloud Firestore Structure

The `product_table` collection in Cloud Firestore contains product stock and pricing documents:

| Field Name | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `product_id` | String | Unique Identifier | `"PROD-101"` |
| `product_quantity` | Number (Integer) | Available Stock Quantity | `50` |
| `product_type` | String | Product Category / Type | `"Chicken Inasal"` |
| `product_price` | Number (Double) | Unit Price | `189.00` |

---

## 👥 `users_table` Cloud Firestore Structure

The `users_table` collection in Cloud Firestore contains customer profile documents:

| Field Name | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `first_name` | String | First Name | `"Juan"` |
| `middle_name` | String | Middle Name | `"Santos"` |
| `last_name` | String | Last Name | `"Dela Cruz"` |
| `birthday` | String | Birthday | `"1998-05-15"` |
| `address` | String | Delivery Address | `"123 Governor Drive, Dasmariñas, Cavite"` |
| `email_address` | String | Primary Identifier / Email | `"juan.delacruz@example.com"` |
| `phone_number` | String | Contact Phone | `"09123456789"` |

---

## 🚀 3-Minute Setup: Connecting Your Firebase Project

### Step 1: Create a Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **"Add project"** and name it (e.g., `ecommerce-delivery-app`).
3. (Optional) Disable Google Analytics for faster setup, then click **"Create project"**.

---

### Step 2: Enable Cloud Firestore
1. In your Firebase Console, click on **Build** ➔ **Firestore Database** in the left sidebar.
2. Click **"Create database"**.
3. Choose a location (e.g., `asia-southeast1` for Singapore/Philippines).
4. Select **"Start in test mode"** (allows immediate read/write access during development and class demos) and click **Enable**.

---

### Step 3: Connect the Laravel Backend
1. In the Firebase Console, click the **Settings Gear ⚙️** (next to Project Overview) ➔ **Project settings**.
2. Note your **Project ID** (e.g., `ecommerce-delivery-app-12345`).
3. Click the **"Service accounts"** tab.
4. Click **"Generate new private key"** ➔ click **"Generate key"**. A `.json` file will download to your computer.
5. Place that downloaded file in your Laravel project at:
   ```bash
   mkdir -p /home/rexsm/Projects/Code/E-commerce/ECOMMERCE_MOBILE/ecommerce_backend/storage/app/firebase
   # Rename and copy your downloaded json file:
   cp /path/to/downloaded-key.json /home/rexsm/Projects/Code/E-commerce/ECOMMERCE_MOBILE/ecommerce_backend/storage/app/firebase/service-account.json
   ```
6. Open your Laravel `.env` file (`ecommerce_backend/.env`) and add:
   ```env
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_CREDENTIALS=storage/app/firebase/service-account.json
   ```

---

### Step 4: Connect the Flutter Mobile App
Open [lib/services/firebase_order_service.dart](file:///home/rexsm/Projects/Code/E-commerce/ECOMMERCE_MOBILE/ecommerce_frontend/lib/services/firebase_order_service.dart) and paste your **Project ID**:

```dart
// lib/services/firebase_order_service.dart
static const String firebaseProjectId = 'your-project-id';
```

---

## 🧪 How to Verify the Hybrid Sync

Once your Project ID is added:

1. **Start the Laravel Server**:
   ```bash
   cd /home/rexsm/Projects/Code/E-commerce/ECOMMERCE_MOBILE/ecommerce_backend
   php artisan serve
   ```
2. **Place an Order on the Phone or run this quick tinker test**:
   ```bash
   php artisan tinker --execute="App\Services\FirebaseService::syncOrder(App\Models\Order::first());"
   ```
3. **Open Firebase Console ➔ Firestore Database**:
   - You will see an `orders` collection.
   - Each order (`ORD-DEMO001`, `ORD-XXXX`) will appear as a live document with its status, items, and total amount!
4. **Change the Status in Admin**:
   - Go to `http://localhost:8000/admin/orders` and click **"Dispatch"**.
   - Watch the document in Firebase Console change its status field to `dispatched` in real-time!
