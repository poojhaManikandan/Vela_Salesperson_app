# Velan — UI Only (Flutter, Material 3)

A frontend-only Flutter scaffold for **Velan**, a retail billing app.
No backend, no database, no API calls, no state-management packages —
everything runs on hardcoded dummy data purely to demonstrate the UI/UX.

## Screens included
1. Splash Screen
2. Login Screen (Employee ID + Password)
3. Home Screen (search, categories, product grid, cart icon)
4. Product Screen (image, price, stock, Add to Cart)
5. Cart Screen (quantity stepper, remove, subtotal/tax/total, Generate Bill)
6. Bill Screen (bill number, date, employee, items, Print/Save)
7. Printer Screen (printer list, Connect, Print)
8. Bill History Screen (search, View, Reprint)
9. Settings Screen (profile, printer settings, theme toggle, logout)

## Run it
```bash
flutter pub get
flutter run
```

## Project structure
```
lib/
  main.dart              # App entry + MaterialApp (Material 3 theme)
  theme/app_theme.dart    # Blue & white Material 3 theme
  models/                 # Plain data classes (Product, Bill, Printer...)
  data/
    dummy_data.dart        # Hardcoded mock products, bills, printers
    cart_store.dart         # In-memory cart list (UI state only)
  screens/                 # One file per screen (see list above)
  widgets/                  # Reusable pieces: ProductCard, PrimaryButton,
                             # AppSearchField, SectionTitle, EmptyState, etc.
```

## Notes
- Cart state is held in a simple in-memory list (`CartStore`) purely so the
  Cart/Bill screens have something to render — this is UI state, not
  business logic, persistence, or a backend integration.
- Product images are loaded from network URLs (Unsplash placeholders) with
  graceful fallback icons if offline.
- Bottom navigation (Shop / Bills / Settings) ties Home, Bill History, and
  Settings together for smooth in-app navigation.
- Layout uses `LayoutBuilder` / `SliverLayoutBuilder` so the product grid
  adapts between phone and tablet/iPad widths.
