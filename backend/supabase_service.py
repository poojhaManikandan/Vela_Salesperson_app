import os
import json
import uuid
from datetime import datetime
import requests
from dotenv import load_dotenv

# Load environment variables from .env file if available
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(BASE_DIR, '.env')
if os.path.exists(env_path):
    load_dotenv(env_path)

# Single Supabase project used for BOTH GST and Non-GST bills
SUPABASE_URL = os.getenv('SUPABASE_URL', '').rstrip('/')
SUPABASE_KEY = os.getenv('SUPABASE_KEY', '')

# Only Non-GST bills go into the salesperson_bills table (it belongs to the Non-GST app)
SALESPERSON_BILLS_TABLE = 'salesperson_bills'

# GST bills go into the gst_bills table (same columns as salesperson_bills + gst)
GST_BILLS_TABLE = 'gst_bills'


def is_supabase_configured():
    """Checks if valid Supabase credentials are set in environment."""
    return (
        bool(SUPABASE_URL) and
        bool(SUPABASE_KEY) and
        'your-supabase-project' not in SUPABASE_URL and
        'your-supabase-anon' not in SUPABASE_KEY
    )


def _normalize_payment_type(payment_type):
    """
    Maps app payment modes to values accepted by the DB check
    constraint on 'salesperson_bills' (Cash, UPI, QR, Card, Credit).
    """
    pt = str(payment_type or 'Cash').strip()
    pt_lower = pt.lower()

    if pt_lower in ('upi / qr', 'upi', 'upi/qr', 'upiqr', 'gpay', 'phonepe', 'google pay', 'phone pay'):
        return 'UPI'
    if pt_lower in ('qr', 'qr code', 'qrcode', 'scan & pay'):
        return 'QR'
    if pt_lower in ('cash', 'cash on delivery', 'cod'):
        return 'Cash'
    if pt_lower in ('card', 'debit card', 'credit card', 'card payment'):
        return 'Card'
    if pt_lower in ('credit', 'credit bill', 'credit payment'):
        return 'Credit'
    return pt


def _normalize_status(status):
    """
    Maps any incoming bill status to a valid Supabase value.
    Usually 'PENDING', 'PAID', or 'REFUNDED'.
    """
    if not status:
        return 'PENDING'
        
    s_upper = str(status).strip().upper()
    if s_upper in ('PAID', 'COMPLETED'):
        return 'PAID'
    if s_upper in ('REFUNDED', 'VOID', 'VOIDED', 'CANCELLED'):
        return 'REFUNDED'
    return 'PENDING'


def extract_bill_row(bill_data):
    """
    Transforms a bill JSON payload into a single row dict matching
    the 'salesperson_bills' table schema.
    """
    if not isinstance(bill_data, dict):
        return None

    items = bill_data.get('items', [])
    if not isinstance(items, list):
        items = []

    # salesman_id is uuid (nullable) — pass as string uuid or None
    raw_salesman = bill_data.get('salesman_id')
    
    # If the user passed '1' or an integer, but the column is UUID, it will fail in Supabase.
    # We will only pass it if it looks like a valid UUID (length >= 32).
    salesman_id = None
    if raw_salesman and str(raw_salesman).strip() not in ('0', ''):
        s_id_str = str(raw_salesman).strip()
        if len(s_id_str) >= 32:
            salesman_id = s_id_str

    now_iso = datetime.now().astimezone().isoformat()

    row = {
        "id": str(bill_data.get('id') or bill_data.get('bill_id') or uuid.uuid4()),
        "submitted_by": str(
            bill_data.get('submitted_by') or bill_data.get('employeeName') or 'Unknown Cashier'
        ),
        "customer_id": str(bill_data.get('customer_id')) if bill_data.get('customer_id') else None,
        "customer_name": str(bill_data.get('customer_name') or 'Walk-in Customer'),
        "customer_phone": str(
            bill_data.get('customer_phone') or bill_data.get('customerPhone') or ''
        ),
        "payment_type": _normalize_payment_type(
            bill_data.get('payment_type') or bill_data.get('payment_mode') or 'Cash'
        ),
        "sales_type": str(bill_data.get('sales_type') or 'Retail'),
        "price_list": str(bill_data.get('price_list') or 'Retail'),
        # Send items as a list (not a json string) — Supabase JSONB needs a native object
        "items": items if isinstance(items, list) else [],
        "grand_total": float(bill_data.get('total') or bill_data.get('grand_total', 0.0) or 0.0),
        "status": _normalize_status(bill_data.get('status')),
        "created_at": str(bill_data.get('created_at') or now_iso),
        "updated_at": str(bill_data.get('updated_at') or now_iso),
        "processed_at": str(bill_data.get('processed_at')) if bill_data.get('processed_at') else None,
    }

    # Only include salesman_id if it has a value (avoids NOT NULL constraint if column has no default)
    if salesman_id is not None:
        row["salesman_id"] = salesman_id

    # --- Payment tracking (amount_paid / balance) ---
    amount_paid = float(bill_data.get('amount_paid') or bill_data.get('amountPaid') or 0.0)
    grand_total  = float(row.get('grand_total') or 0.0)
    balance      = max(round(grand_total - amount_paid, 2), 0.0)
    row["amount_paid"]     = amount_paid
    row["balance"]         = balance
    row["payment_status"]  = 'Paid' if amount_paid >= grand_total and grand_total > 0 else 'Pending'

    return row


def push_bill_to_supabase(bill_data, label='BILL', table=None, extra_fields=None):
    """
    Upserts a single bill row into a Supabase table using the
    Supabase REST API (PostgREST).

    Args:
        bill_data     : Formatted bill dict.
        label         : 'GST' or 'NON-GST' — used only for log messages.
        table         : Target table name (defaults to SALESPERSON_BILLS_TABLE).
        extra_fields  : Optional dict of extra columns merged into the row.
    """
    target_table = table or SALESPERSON_BILLS_TABLE
    if not is_supabase_configured():
        print(
            f"[SUPABASE NOTICE] [{label}] Credentials not configured in .env. "
            f"Skipped API push to '{target_table}'."
        )
        return False, "Supabase credentials not configured in backend/.env"

    row = extract_bill_row(bill_data)
    if not row:
        return False, "Invalid bill payload"
    if extra_fields:
        row.update(extra_fields)

    endpoint = f"{SUPABASE_URL}/rest/v1/{target_table}?on_conflict=id"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }

    try:
        response = requests.post(endpoint, headers=headers, json=row, timeout=10)
        if response.status_code in (200, 201, 204):
            print(
                f"[SUPABASE SUCCESS] [{label}] Uploaded bill {row['id']} "
                f"into '{target_table}' table!"
            )
            return True, f"Successfully uploaded bill {row['id']} into '{target_table}'"
        else:
            err_msg = f"HTTP {response.status_code}: {response.text}"
            print(f"[SUPABASE ERROR] [{label}] Failed: {err_msg}")
            # Write full error + row to a log file (terminal truncates long output)
            log_path = os.path.join(BASE_DIR, 'supabase_error.log')
            with open(log_path, 'w', encoding='utf-8') as lf:
                lf.write(f"=== SUPABASE ERROR [{label}] ===\n")
                lf.write(f"Table: {target_table}\n")
                lf.write(f"HTTP Status: {response.status_code}\n")
                lf.write(f"Response: {response.text}\n\n")
                lf.write(f"=== ROW SENT ===\n")
                lf.write(json.dumps(row, default=str, indent=2))
            print(f"[SUPABASE DEBUG] Full error written to: {log_path}")
            return False, err_msg
    except Exception as e:
        err_msg = str(e)
        print(f"[SUPABASE EXCEPTION] [{label}] Request failed: {err_msg}")
        return False, err_msg


def sync_gst_bill(bill_data):
    """
    Syncs a GST bill into the Supabase 'gst_bills' table.
    gst_bills schema:
      id, submitted_by, customer_name, customer_phone, payment_type,
      sales_type, price_list, items (jsonb), grand_total, status,
      created_at, updated_at, processed_at, salesman_id (INTEGER), customer_id (uuid), gst (numeric)
    """
    if not is_supabase_configured():
        return False, "Supabase credentials not configured in backend/.env"

    items = bill_data.get('items', [])
    if not isinstance(items, list):
        items = []

    # Compute GST amount (5% of subtotal if not provided)
    gst_amount = float(bill_data.get('tax') or bill_data.get('gst') or 0.0)
    if gst_amount <= 0:
        subtotal = sum(
            float(item.get('total') or 0.0)
            for item in items
            if isinstance(item, dict)
        )
        gst_amount = round(subtotal * 0.05, 2)

    # salesman_id is INTEGER in gst_bills
    raw_salesman = bill_data.get('salesman_id')
    try:
        salesman_id = int(raw_salesman) if raw_salesman not in (None, '', 'None') else 0
    except (TypeError, ValueError):
        salesman_id = 0

    now_iso = datetime.now().astimezone().isoformat()

    row = {
        "id":             str(bill_data.get('id') or bill_data.get('bill_id') or uuid.uuid4()),
        "submitted_by":   str(bill_data.get('submitted_by') or bill_data.get('employeeName') or 'Unknown Cashier'),
        "customer_id":    str(bill_data.get('customer_id')) if bill_data.get('customer_id') else None,
        "customer_name":  str(bill_data.get('customer_name') or 'Walk-in Customer'),
        "customer_phone": str(bill_data.get('customer_phone') or bill_data.get('customerPhone') or ''),
        "payment_type":   _normalize_payment_type(bill_data.get('payment_type') or bill_data.get('payment_mode') or 'Cash'),
        "sales_type":     str(bill_data.get('sales_type') or 'Retail'),
        "price_list":     str(bill_data.get('price_list') or 'Retail'),
        # Send items as a list (not a json string) — Supabase JSONB needs a native object
        "items":          items if isinstance(items, list) else [],
        "grand_total":    float(bill_data.get('total') or bill_data.get('grand_total') or 0.0),
        "gst":            gst_amount,
        "status":         _normalize_status(bill_data.get('status')),
        "created_at":     str(bill_data.get('created_at') or now_iso),
        "updated_at":     str(bill_data.get('updated_at') or now_iso),
        "processed_at":   str(bill_data.get('processed_at')) if bill_data.get('processed_at') else None,
        "salesman_id":    salesman_id,
    }

    # --- Payment tracking for gst_bills (update_payment, balance, payment_status) ---
    amount_paid    = float(bill_data.get('amount_paid') or bill_data.get('amountPaid') or 0.0)
    grand_total_v  = float(row.get('grand_total') or 0.0)
    balance        = max(round(grand_total_v - amount_paid, 2), 0.0)
    row["update_payment"]  = amount_paid
    row["balance"]         = balance
    row["payment_status"]  = 'Paid' if amount_paid >= grand_total_v and grand_total_v > 0 else 'Pending'

    endpoint = f"{SUPABASE_URL}/rest/v1/{GST_BILLS_TABLE}?on_conflict=id"
    headers = {
        "apikey":        SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type":  "application/json",
        "Prefer":        "resolution=merge-duplicates"
    }

    try:
        response = requests.post(endpoint, headers=headers, json=row, timeout=10)
        if response.status_code in (200, 201, 204):
            print(f"[SUPABASE SUCCESS] [GST] Uploaded bill {row['id']} into '{GST_BILLS_TABLE}' table!")
            return True, f"Successfully uploaded bill {row['id']} into '{GST_BILLS_TABLE}'"
        else:
            err_msg = f"HTTP {response.status_code}: {response.text}"
            print(f"[SUPABASE ERROR] [GST] Failed to push bill: {err_msg}")
            print(f"[SUPABASE DEBUG] Row sent: {json.dumps(row, default=str, indent=2)}")
            return False, err_msg
    except Exception as e:
        err_msg = str(e)
        print(f"[SUPABASE EXCEPTION] [GST] Request failed: {err_msg}")
        return False, err_msg



def sync_nongst_bill(bill_data):
    """
    Syncs a Non-GST bill into Supabase 'salesperson_bills' table.
    Uses the same Supabase project as GST (SUPABASE_URL / SUPABASE_KEY).
    """
    return push_bill_to_supabase(bill_data, label='NON-GST')


def fetch_customers(search_query=''):
    """Fetches customer names from Supabase and filters by name/phone when requested."""
    if not is_supabase_configured():
        return [], "Supabase credentials not configured in backend/.env"

    endpoint = f"{SUPABASE_URL}/rest/v1/customers"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Accept": "application/json",
    }
    params = {
        "select": "*",
        "limit": "200",
    }

    try:
        response = requests.get(endpoint, headers=headers, params=params, timeout=15)
        if response.status_code != 200:
            err_msg = f"HTTP {response.status_code}: {response.text[:300]}"
            print(f"[SUPABASE ERROR] Failed to fetch customers: {err_msg}")
            return [], err_msg

        rows = response.json() or []
        customers = []
        seen = set()
        q = (search_query or '').strip().lower()

        for row in rows:
            if not isinstance(row, dict):
                continue
            customer_id = str(row.get('customer_id') or row.get('id') or '').strip()
            name = str(
                row.get('customer_name') or row.get('name') or row.get('customer') or ''
            ).strip()
            phone = str(
                row.get('customer_phone') or row.get('phone') or row.get('mobile') or ''
            ).strip()

            if not name:
                continue

            key = (customer_id or name).lower()
            if key in seen:
                continue
            seen.add(key)

            if q and not (name.lower().find(q) >= 0 or phone.lower().find(q) >= 0):
                continue

            customers.append({
                "id": customer_id,
                "name": name,
                "phone": phone,
            })

        return customers, None
    except Exception as e:
        err_msg = str(e)
        print(f"[SUPABASE EXCEPTION] Failed to fetch customers: {err_msg}")
        return [], err_msg


def fetch_products():
    """
    Fetches active products from the Supabase 'products' table and resolves
    the category name using the public.categories table via category_id.

    Returns:
        tuple (products_list, error_message). products_list is a list of dicts
        in the shape expected by the Flutter frontend, or empty on failure.
    """
    if not is_supabase_configured():
        return [], "Supabase credentials not configured in backend/.env"

    category_map = {}
    try:
        category_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/categories",
            headers={
                "apikey": SUPABASE_KEY,
                "Authorization": f"Bearer {SUPABASE_KEY}",
                "Accept": "application/json",
            },
            params={"select": "category_id,name", "is_active": "eq.true"},
            timeout=15,
        )
        if category_response.status_code == 200:
            for cat in category_response.json():
                if not isinstance(cat, dict):
                    continue
                category_id = str(cat.get('category_id') or '').strip()
                name = str(cat.get('name') or '').strip()
                if category_id and name:
                    category_map[category_id] = name
    except Exception as e:
        print(f"[SUPABASE NOTICE] Failed to load category map: {e}")

    select = ",".join([
        "product_id",
        "product_name",
        "category_id",
        "group_name",
        "selling_price",
        "on_hand",
        "product_image",
        "unit",
        "gst_percentage",
        "inventory(current_stock)",
    ])
    endpoint = f"{SUPABASE_URL}/rest/v1/products"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Accept": "application/json",
    }
    params = {
        "select": select,
        "status": "eq.active",
        "order": "product_name.asc",
        "limit": "1000",
    }

    try:
        response = requests.get(endpoint, headers=headers, params=params, timeout=15)
        if response.status_code != 200:
            err_msg = f"HTTP {response.status_code}: {response.text[:300]}"
            print(f"[SUPABASE ERROR] Failed to fetch products: {err_msg}")
            return [], err_msg

        raw_rows = response.json()
        products = []
        skipped = 0
        for row in raw_rows:
            if not isinstance(row, dict):
                continue
            try:
                product_id = str(row.get('product_id') or '').strip()
                name = str(row.get('product_name') or '').strip()
                category_id = str(row.get('category_id') or '').strip()
                category = category_map.get(category_id) or str(row.get('group_name') or '').strip() or 'General'
                image = str(row.get('product_image') or '').strip()
                unit = str(row.get('unit') or '').strip() or 'pcs'

                price = float(row.get('selling_price') or 0.0)
                gst_pct = float(row.get('gst_percentage') or 0.0)

                if not product_id or not name or price <= 0:
                    skipped += 1
                    if skipped <= 3:
                        print(f"[SUPABASE SKIP] Incomplete product '{name or product_id}' "
                              f"(id={bool(product_id)}, name={bool(name)}, price={price})")
                    continue

                inventory_rows = row.get('inventory') or []
                stock = sum(
                    float(i.get('current_stock') or 0.0)
                    for i in inventory_rows
                    if isinstance(i, dict)
                )
                if stock == 0 and not inventory_rows:
                    stock = float(row.get('on_hand') or 0.0)

                products.append({
                    "id": product_id,
                    "name": name,
                    "category": category,
                    "price": int(price) if price.is_integer() else round(price, 2),
                    "stock": max(int(stock), 0),
                    "imageUrl": image,
                    "unit": unit,
                    "isGst": gst_pct > 0,
                })
            except (TypeError, ValueError) as e:
                skipped += 1
                print(f"[SUPABASE SKIP] Bad product row {row.get('product_id')}: {e}")
                continue

        print(f"[SUPABASE SUCCESS] Fetched {len(products)} complete active products "
              f"({skipped} skipped as incomplete); categories mapped from {len(category_map)} category rows")
        return products, None
    except Exception as e:
        err_msg = str(e)
        print(f"[SUPABASE EXCEPTION] Failed to fetch products: {err_msg}")
        return [], err_msg

def update_product_price(product_id, new_price):
    if not is_supabase_configured():
        return False, "Supabase credentials not configured in backend/.env"
        
    endpoint = f"{SUPABASE_URL}/rest/v1/products"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal"
    }
    params = {
        "product_id": f"eq.{product_id}"
    }
    
    try:
        response = requests.patch(
            endpoint, 
            headers=headers, 
            params=params, 
            json={"selling_price": new_price},
            timeout=10
        )
        if response.status_code in (200, 204):
            return True, None
        return False, f"HTTP {response.status_code}: {response.text}"
    except Exception as e:
        return False, str(e)