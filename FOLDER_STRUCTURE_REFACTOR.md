# 📁 Frontend Folder Modularization & Architecture Documentation

**Date:** October 2, 2026  
**Status:** Completed & Verified  

---

## 1. Context & Motivation
Previously, the customer-facing storefront in `ecommerce_frontend` suffered from **monolithic file bloat**:
- `lib/main.dart` was **2,437 lines long**, containing the data models (`FoodItem`, `CartItem`, default catalog list), the full customer storefront screen (`HomeScreen`), the item details modal, the shopping cart modal, and the customer order history/profile modal.
- This made Git merges between mobile and web prone to severe merge conflicts, broke clean separation of concerns, and made finding/editing specific features cumbersome.

Rather than fragmenting the repository into multiple brittle Flutter packages with fragile path dependencies, we adopted a **Single-Project Modular Feature Architecture**.

---

## 2. Structural Changes Overview

### Before:
```
lib/
├── main.dart                 (2,437 lines — models, sheets, storefront all mixed together)
├── admin/                    (Admin portal views)
├── auth/                     (Login & Signup)
├── models/                   (Partial models)
├── services/                 (Backend API services)
└── widgets/                  (Reusable widgets)
```

### After:
```
lib/
├── main.dart                                (43 lines — clean entrypoint, theme & route table only)
│
├── models/
│   ├── food_item.dart                       (NEW: FoodItem, CartItem, & defaultFoodCatalog fallback)
│   ├── order_model.dart
│   ├── product_model.dart
│   └── user_model.dart
│
├── customer/                                (NEW: Dedicated Customer Domain)
│   ├── home_screen.dart                     (Customer storefront, responsive catalog & filters)
│   └── sheets/
│       ├── item_detail_bottom_sheet.dart    (Isolated product customization modal)
│       ├── cart_bottom_sheet.dart           (Isolated shopping cart & item count sheet)
│       └── profile_bottom_sheet.dart        (Isolated customer order history & review dialog)
│
├── admin/                                   (Store Owner & Merchant Domain)
│   ├── admin_layout.dart
│   ├── orders_view.dart
│   ├── products_view.dart
│   └── users_view.dart
│
├── auth/                                    (Customer Authentication Domain)
│   ├── login_page.dart
│   └── signup_page.dart
│
├── landing_page.dart                        (Public marketing landing page)
│
├── services/                                (Shared backend API, checkout & adapters)
└── widgets/                                 (Shared cross-feature UI widgets, e.g. QR modal)
```

---

## 3. Specific File Modifications & Creations

### 1. `lib/models/food_item.dart` *(NEW)*
- **Responsibility:** Holds the `FoodItem` class, `CartItem` class, and the `defaultFoodCatalog` fallback list.
- **Dependencies:** None (Pure Dart model).

### 2. `lib/customer/sheets/item_detail_bottom_sheet.dart` *(NEW)*
- **Responsibility:** Renders the customized food item modal, special instruction input, dynamic quantity selector, and constrained desktop width (`maxWidth: 560`).

### 3. `lib/customer/sheets/cart_bottom_sheet.dart` *(NEW)*
- **Responsibility:** Renders the user's active shopping cart, empty state with "Browse Menu", item removal triggers, and checkout action.

### 4. `lib/customer/sheets/profile_bottom_sheet.dart` *(NEW)*
- **Responsibility:** Renders customer order history, live order statuses (`PENDING`, `PREPARING`, `COMPLETED`), and the 5-star review submission dialog.

### 5. `lib/customer/home_screen.dart` *(NEW)*
- **Responsibility:** The responsive customer storefront. Dynamically renders 2-to-5 column food grids, category filters, hero banner, search bar, and invokes the isolated sheets above.

### 6. `lib/main.dart` *(REFACTORED)*
- **Line Count Reduced:** From **2,437 lines** down to **43 lines**.
- **Content:** Retains only `main()`, `MyApp`, theme configuration, and the top-level route table (`/`, `/shop`, `/admin`, `/login`, `/signup`).

---

## 4. Verification & Testing
- Ran `flutter analyze lib/main.dart lib/customer/ lib/models/food_item.dart`:
  - **Zero compile-time errors or broken dependencies.**
  - All routes, modals, and data models cleanly reference each other via relative imports.
