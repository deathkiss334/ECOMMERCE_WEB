# E-Commerce Project Roadmap & Rubric Alignment

This roadmap bridges your current **Flutter Mobile UI** and **Laravel Skeleton** to the final **Project Presentation Outline and Rubrics**, ensuring a score of 5 on all criteria.

## Phase 1: Database & Backend Foundation (Laravel)
**Target Rubrics:** Product Catalog (10%), Shopping Cart & Payment (20%), Order Processing (20%)

1. **Database Schema & Migrations**
   - Create migrations for: `Categories`, `Products`, `Product_Variants` (for inventory management).
   - Create migrations for: `Carts`, `Orders`, `Order_Items`, `Payments`.
   - **Rubric Alignment (Score 5):** Ensure "synchronized with inventory" by adding quantity locks and `stock_quantity` decrements when an order is created.
2. **API Development & Authentication**
   - Run `php artisan install:api` and configure **Sanctum** for token-based authentication.
   - Build RESTful endpoints: `/api/products`, `/api/cart`, `/api/checkout`, `/api/orders`.
3. **Data Seeding**
   - Seed the database with the "Filipino favorites" currently hardcoded in your Flutter UI to demonstrate a live, populated catalog.

## Phase 2: Core Frontend Integration (Flutter)
**Target Rubrics:** Landing Page / Storefront (15%), Product Catalog (10%)

1. **State Management**
   - Implement **Provider**, **Riverpod**, or **Bloc** to manage global state (User Auth, Cart Items, App Theme).
2. **Dynamic UI Binding**
   - Replace the hardcoded Flutter UI with API response data from Laravel (`/api/products`).
   - Implement real-time search functionality and category filtering.
   - **Rubric Alignment (Score 5):** "Product information is complete, accurate, persuasive, searchable..."

## Phase 3: The Checkout & Payment Engine (High Priority - 20%)
**Target Rubrics:** Shopping Cart, Checkout, and Payment (20%)

1. **Cart Logic (Flutter + Laravel)**
   - Allow users to modify quantities and remove items.
   - Calculate totals dynamically (Subtotal + Delivery Fee).
2. **Payment Gateway Integration**
   - Integrate **PayMongo** (or similar) into Laravel for GCash/Maya/Card processing.
   - Build the webhook route (`/api/webhooks/payment`) in Laravel to listen for successful payments.
3. **Checkout Experience (Flutter)**
   - Add a Webview/In-App browser for the user to complete E-Wallet flows.
   - **Rubric Alignment (Score 5):** "Checkout process is secure, simple, transparent... immediate transaction confirmation." Show failed-payment handling cleanly in the UI.

## Phase 4: Order Fulfillment & Admin Dashboard (High Priority - 20%)
**Target Rubrics:** Order Processing, Delivery, Returns, and Refunds (20%)

1. **Admin Panel (Web Backend)**
   - Build a simple Laravel Livewire or Filament admin dashboard to view incoming orders.
   - Allow admins to change order states: `Pending` -> `Preparing` -> `Dispatched` -> `Delivered`.
2. **Order Tracking (Flutter App)**
   - Create an "Order History" and "Track Order" page in the mobile app where users see real-time status updates synced from the backend.
   - **Rubric Alignment (Score 5):** "Orders are accurately recorded, processed, tracked, and completed within defined service standards."

## Phase 5: Marketing & Customer Service (25% Combined)
**Target Rubrics:** Digital Marketing (15%), Customer Service & Retention (10%)

1. **Marketing Links & Analytics**
   - Ensure working social media links exist in the Profile tab.
   - Add dummy (or real) promo codes during the checkout phase (e.g., `WELCOME10`).
   - Set up Firebase Analytics for tracking "Add to Cart" and "Checkout" conversions.
2. **Customer Support Features**
   - Add an integrated FAQ and "Contact Support" button in the mobile app.
   - Add a post-order Product Review / 5-Star rating system.
   - **Rubric Alignment (Score 5):** "The SME actively monitors satisfaction, complaints, repeat purchases, reviews, and loyalty."

## Phase 6: Presentation & Demonstration Prep (10%)
**Target Rubrics:** Presentation and Quality of Supporting Evidence (10%)

- **Live Demo Script (Aligned with Outline):**
  1. Show the **"Problem"** (Manual processes).
  2. Exhibit the **Storefront** (Live search, filters).
  3. Perform a **Live Checkout** using a test E-wallet account.
  4. Show the **Admin Dashboard** dispatching the order.
  5. Show the **Customer App** receiving the notification/tracking update.
  6. Present **Growth & Analytics** (Show Firebase dashboard or Admin sales charts).
