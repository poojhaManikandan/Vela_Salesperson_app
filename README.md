# Velan — Billing & Inventory POS (Flutter + Flask)

A retail billing app for **Velan / Vela Agency**: Flutter (Material 3) frontend
plus a local Flask backend that syncs bills to Supabase. GST and non-GST bill
halves are split and written to separate tables/JSON stores.

## Screens
1. Splash Screen
2. Login Screen (mobile number)
3. Home Screen (search, categories, product grid, cart)
4. Product Screen (image, price, stock, Add to Cart)
5. Cart Screen (quantity stepper, remove, subtotal/tax/total, Generate Bill)
6. Bill Screen (tax invoice + receipt, print, new sale)
7. Printer Screen (Bluetooth thermal printer scan/connect/test)
8. Bill History Screen (search, view receipt, reprint)
9. Settings Screen (profile, dark theme, notifications, logout)

## Run it
Backend first, then the app.

```bash
# 1) Backend (requires backend/.env with SUPABASE_URL + SUPABASE_KEY)
pip install -r backend/requirements.txt
python backend/app.py          # serves http://127.0.0.1:5000

# 2) App
flutter pub get
flutter run
```

`backend/.env.example` shows the required environment variables. Copy it to
`backend/.env` and fill in your Supabase project URL and service-role key.

## Backend
- `backend/app.py` — Flask API (`/api/products`, `/api/bills`, split logic that
  routes GST vs non-GST items into separate JSON stores and Supabase tables).
- `backend/supabase_service.py` — Supabase client + bill sync
  (`gst_bills` and `salesperson_bills` tables), payment-type normalization
  (`UPI / QR` → `UPI`), product fetch.
- `backend/*.sql` — one-time Supabase setup/import scripts (run in the
  Supabase SQL Editor). `gst_bills_setup.sql` creates `gst_bills`;
  `supabase_setup.sql` creates `salesperson_bills`.
- `backend/data/bills/` — runtime local JSON store the backend writes on every
  save (generated, git-ignored).

## Tests
```bash
flutter test        # widget/module-flow tests (hermetic, no backend needed)
flutter analyze
```

## Notes
- Cart state lives in an in-memory `CartStore`; persisted bills and the
  dark-theme preference use `SharedPreferences`.
- Product catalog is fetched from the backend (Supabase `products` table).
  In tests, `ApiService.debugProducts` provides a hermetic data seam.
- Receipts are rendered as a white "thermal paper" card in both light/dark
  theme; the splash screen is intentionally brand-green.
- The product grid adapts between phone and tablet widths via
  `LayoutBuilder` / `SliverLayoutBuilder`.
