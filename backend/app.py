# Trigger reload
import os
import json
import uuid
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
from supabase_service import fetch_products, fetch_customers, sync_nongst_bill, sync_gst_bill
from supabase_service import fetch_customers, fetch_products, sync_gst_bill, sync_nongst_bill

app = Flask(__name__)
CORS(app)  # Enable Cross-Origin Resource Sharing for Flutter Web / Desktop

# Base paths for Dual GST & NON-GST JSON Databases
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
GST_BILLS_DIR = os.path.join(BASE_DIR, 'data', 'bills', 'gst')
NONGST_BILLS_DIR = os.path.join(BASE_DIR, 'data', 'bills', 'nongst')

# Ensure both GST & NON-GST storage directories exist
os.makedirs(GST_BILLS_DIR, exist_ok=True)
os.makedirs(NONGST_BILLS_DIR, exist_ok=True)


def _clean_number(value, default=0.0):
    """Returns int when the value is integral, otherwise float rounded to 2dp."""
    if value is None:
        return default
    try:
        num = float(value)
    except (TypeError, ValueError):
        return default
    return int(num) if num.is_integer() else round(num, 2)


def _normalize_payment_type(payment_type):
    """Maps app payment modes to DB-accepted values: Cash, UPI, QR, Card, Credit."""
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


def _normalize_bill_status(status):
    """
    Maps any incoming bill status to 'PENDING'.
    The live Supabase database constraint 'salesperson_bills_status_check'
    ONLY allows the exact string 'PENDING'.
    """
    return 'PENDING'


def format_items_to_salesperson_bills_schema(items):
    """
    Formats items array into the 'items' jsonb format of salesperson_bills:
    [
      {
        "product_id": "P001",
        "product_name": "Product A",
        "quantity": 5,
        "unit_price": 100,
        "discount": 10,
        "total": 450
      }
    ]
    """
    formatted_items = []
    if not isinstance(items, list):
        return formatted_items

    for idx, item in enumerate(items, start=1):
        if not isinstance(item, dict):
            continue

        prod = item.get('product') if isinstance(item.get('product'), dict) else item

        product_id = str(
            item.get('product_id') or
            prod.get('product_id') or
            prod.get('id') or
            f"P{idx:03d}"
        )

        product_name = str(
            item.get('product_name') or
            prod.get('name') or
            prod.get('description') or
            item.get('description') or
            item.get('name') or
            'Item'
        )

        quantity = _clean_number(item.get('quantity'), 1)

        unit_price = _clean_number(
            prod.get('price') or
            prod.get('rate') or
            item.get('unit_price') or
            item.get('rate') or
            item.get('price') or
            0.0
        )

        discount = _clean_number(item.get('discount') or item.get('discount_percent') or 0.0)

        total = _clean_number(item.get('total') or 0.0)
        if total <= 0:
            if item.get('amount'):
                total = _clean_number(item.get('amount'))
            else:
                total = _clean_number(unit_price * quantity * (1 - discount / 100.0))

        formatted_items.append({
            "product_id": product_id,
            "product_name": product_name,
            "quantity": quantity,
            "unit_price": unit_price,
            "discount": discount,
            "total": total
        })

    return formatted_items


def format_bill_to_requested_schema(bill_data):
    """
    Transforms any bill data payload into the salesperson_bills schema:
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type,
    sales_type, price_list, items (jsonb), grand_total, status, created_at,
    updated_at, processed_at, salesman_id.
    """
    if not isinstance(bill_data, dict):
        return bill_data

    bill_id = bill_data.get('id') or bill_data.get('bill_id') or str(uuid.uuid4())

    now = datetime.now()
    date_obj = now
    date_raw = bill_data.get('created_at') or bill_data.get('date') or bill_data.get('bill_date')
    if date_raw:
        try:
            clean_str = str(date_raw).replace('Z', '+00:00')
            if 'T' in clean_str:
                date_obj = datetime.fromisoformat(clean_str)
            else:
                time_part = bill_data.get('bill_time', '00:00:00')
                date_obj = datetime.strptime(f"{clean_str} {time_part}", '%Y-%m-%d %H:%M:%S')
        except Exception:
            date_obj = now

    created_at = bill_data.get('created_at') or date_obj.astimezone().isoformat()
    if 'T' not in str(created_at):
        created_at = date_obj.astimezone().isoformat()

    formatted = {
        "id": bill_id,
        "submitted_by": str(bill_data.get('submitted_by') or bill_data.get('employeeName') or 'Unknown Cashier'),
        "customer_id": str(bill_data['customer_id']) if bill_data.get('customer_id') else None,
        "customer_name": str(bill_data.get('customer_name') or bill_data.get('customerName') or 'Walk-in Customer'),
        "customer_phone": str(bill_data.get('customer_phone') or bill_data.get('customerPhone') or ''),
        "payment_type": _normalize_payment_type(
            bill_data.get('payment_type') or bill_data.get('payment_mode') or bill_data.get('paymentMode') or 'Cash'
        ),
        "sales_type": str(bill_data.get('sales_type') or bill_data.get('salesType') or 'Retail'),
        "price_list": str(bill_data.get('price_list') or bill_data.get('priceList') or 'Retail'),
        "items": format_items_to_salesperson_bills_schema(bill_data.get('items', [])),
        "grand_total": float(bill_data.get('total') or bill_data.get('grand_total') or 0.0),
        "status": _normalize_bill_status(str(bill_data.get('status') or 'Pending')),
        "created_at": created_at,
        "updated_at": bill_data.get('updated_at') or created_at,
        "processed_at": bill_data.get('processed_at') or None,
        "salesman_id": str(bill_data.get('salesman_id')) if bill_data.get('salesman_id') not in (None, '', 0, '0') else None
    }

    return formatted


def clean_all_existing_json_files():
    """Formats all existing JSON bill files in gst and nongst directories."""
    for db_dir in [GST_BILLS_DIR, NONGST_BILLS_DIR]:
        if os.path.exists(db_dir):
            for file_name in os.listdir(db_dir):
                if file_name.endswith('.json'):
                    file_path = os.path.join(db_dir, file_name)
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            data = json.load(f)
                        formatted_data = format_bill_to_requested_schema(data)
                        with open(file_path, 'w', encoding='utf-8') as f:
                            json.dump(formatted_data, f, indent=2, ensure_ascii=False)
                    except Exception as e:
                        print(f"[REFORMAT ERROR] {file_name}: {e}")


def migrate_existing_root_files():
    """Migrates legacy files in backend/data/bills/ into gst/ or nongst/ folders."""
    legacy_dir = os.path.join(BASE_DIR, 'data', 'bills')
    if os.path.exists(legacy_dir):
        for item in os.listdir(legacy_dir):
            item_path = os.path.join(legacy_dir, item)
            if os.path.isfile(item_path) and item.endswith('.json'):
                try:
                    with open(item_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                    tax = float(data.get('tax', 0.0))
                    target_dir = GST_BILLS_DIR if tax > 0 else NONGST_BILLS_DIR
                    data['taxType'] = 'GST' if tax > 0 else 'NON_GST'
                    
                    target_path = os.path.join(target_dir, item)
                    formatted_data = format_bill_to_requested_schema(data)
                    with open(target_path, 'w', encoding='utf-8') as f:
                        json.dump(formatted_data, f, indent=2, ensure_ascii=False)
                    
                    os.remove(item_path)
                    print(f"[MIGRATED] Moved legacy bill {item} to {data['taxType']} DB")
                except Exception as e:
                    print(f"[MIGRATION NOTICE] Skip {item}: {e}")


migrate_existing_root_files()
clean_all_existing_json_files()


@app.route('/api/debug/constraint', methods=['GET'])
def get_constraint():
    """Queries Supabase to find the exact allowed values in salesperson_bills_status_check."""
    import requests as req
    from supabase_service import SUPABASE_URL, SUPABASE_KEY
    # Query information_schema via Supabase REST RPC or pg_get_constraintdef
    url = f"{SUPABASE_URL}/rest/v1/rpc/get_status_constraint"
    # Fallback: query pg_constraint directly via the REST API workaround
    # Use the PostgREST information_schema endpoint
    info_url = f"{SUPABASE_URL}/rest/v1/"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Accept": "application/json",
    }
    # Try a test insert with each candidate value
    test_table = f"{SUPABASE_URL}/rest/v1/salesperson_bills"
    candidate_statuses = ['PENDING', 'pending', 'PROCESSING', 'processing',
                          'COMPLETED', 'completed', 'CANCELLED', 'cancelled',
                          'APPROVED', 'PAID', 'paid', 'active', 'ACTIVE',
                          'done', 'DONE', 'submitted', 'SUBMITTED']
    results = {}
    import uuid as _uuid, json as _json
    from datetime import datetime as _dt
    test_id = str(_uuid.uuid4())
    for s in candidate_statuses:
        test_row = {
            "id": str(_uuid.uuid4()),
            "submitted_by": "debug_test",
            "customer_name": "Debug Test",
            "customer_phone": "",
            "payment_type": "Cash",
            "sales_type": "Retail",
            "price_list": "Retail",
            "items": [],
            "grand_total": 0.01,
            "status": s,
            "created_at": _dt.now().astimezone().isoformat(),
            "updated_at": _dt.now().astimezone().isoformat(),
        }
        try:
            r = req.post(
                f"{SUPABASE_URL}/rest/v1/salesperson_bills",
                headers={**headers, "Content-Type": "application/json", "Prefer": "return=minimal"},
                json=test_row,
                timeout=5
            )
            if r.status_code in (200, 201, 204):
                results[s] = "✅ ALLOWED"
                # Delete the test row
                req.delete(
                    f"{SUPABASE_URL}/rest/v1/salesperson_bills?id=eq.{test_row['id']}",
                    headers=headers, timeout=5
                )
            else:
                results[s] = f"❌ {r.status_code}: {r.text[:100]}"
        except Exception as e:
            results[s] = f"ERROR: {e}"
    return jsonify({"allowed_statuses": results})



@app.route('/', methods=['GET'])
def index():
    """Simple root endpoint so browser requests to the API root return a useful response."""
    return jsonify({
        'status': 'online',
        'service': 'Vela Billing API',
        'message': 'Use /api/health or /api/products for app requests',
        'available_endpoints': [
            '/api/health',
            '/api/products',
            '/api/bills',
            '/api/analytics'
        ]
    }), 200


@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint displaying Dual DB Status."""
    return jsonify({
        'status': 'online',
        'framework': 'Flask (Python 3.10)',
        'message': 'Vela Billing Dual Database Service Active',
        'databases': {
            'gst_db': GST_BILLS_DIR,
            'nongst_db': NONGST_BILLS_DIR
        },
        'timestamp': datetime.now().isoformat()
    }), 200

@app.route('/api/products/<product_id>', methods=['PATCH'])
def update_product(product_id):
    """Updates the price of a product in Supabase."""
    data = request.json or {}
    new_price = data.get('price')
    if new_price is None:
        return jsonify({'error': 'price is required'}), 400
        
    from supabase_service import update_product_price
    success, err = update_product_price(product_id, new_price)
    if success:
        return jsonify({'success': True})
    return jsonify({'error': err}), 500



@app.route('/api/bills', methods=['POST'])
def save_bill():
    """
    Receives bill JSON payload and formats it into requested schema (WITHOUT bill_date & bill_time).
    """
    try:
        bill_data = request.get_json()
        if not bill_data or ('billNumber' not in bill_data and 'bill_no' not in bill_data):
            return jsonify({'error': 'Invalid bill payload. Missing bill identifier.'}), 400

        base_bill_number = bill_data.get('billNumber') or bill_data.get('bill_no')
        items = bill_data.get('items', [])

        def item_is_gst(item):
            """Item is GST unless its isGst flag is explicitly False.
            Handles both nested (item['product']) and flat item payloads."""
            nested = item.get('product') if isinstance(item.get('product'), dict) else None
            if nested is not None:
                if nested.get('isGst') is not None:
                    return bool(nested.get('isGst'))
                return nested.get('gst_percentage', 0) not in (None, 0)
            if item.get('isGst') is not None:
                return bool(item.get('isGst'))
            return item.get('gst_percentage', 0) not in (None, 0)

        gst_items = []
        nongst_items = []

        for item in items:
            if item_is_gst(item):
                gst_items.append(item)
            else:
                nongst_items.append(item)

        def compute_subtotal(item_list):
            sub = 0.0
            for it in item_list:
                if isinstance(it.get('product'), dict):
                    p = it['product']
                else:
                    p = it
                price = float(p.get('unit_price') or p.get('price') or p.get('rate') or 0.0)
                qty = int(it.get('quantity', 1))
                sub += price * qty
            return round(sub, 2)

        saved_files = []

        # Case 1: Mixed Transaction -> SPLIT INTO 2 JSON FILES!
        if len(gst_items) > 0 and len(nongst_items) > 0:
            # 1. Direct Conversion & Insertion into Supabase 'gst_order_items'
            gst_subtotal = compute_subtotal(gst_items)
            gst_tax = round(gst_subtotal * 0.05, 2)
            gst_bill_number = f"{base_bill_number}-GST"
            gst_bill = dict(bill_data)
            gst_bill.update({
                'billNumber': gst_bill_number,
                'items': gst_items,
                'subtotal': gst_subtotal,
                'tax': gst_tax,
                'discount': 0.0,
                'total': round(gst_subtotal + gst_tax, 2),
                'taxType': 'GST',
                'isGstSplit': True
            })
            formatted_gst = format_bill_to_requested_schema(gst_bill)
            gst_success, gst_msg = sync_gst_bill(formatted_gst)

            # Local JSON backup
            gst_file_path = os.path.join(GST_BILLS_DIR, f"{gst_bill_number}.json")
            with open(gst_file_path, 'w', encoding='utf-8') as f:
                json.dump(formatted_gst, f, indent=2, ensure_ascii=False)
            saved_files.append(f"backend/data/bills/gst/{gst_bill_number}.json")

            # 2. Direct Conversion & Insertion into Supabase 'salesperson_bills'
            nongst_subtotal = compute_subtotal(nongst_items)
            nongst_bill_number = f"{base_bill_number}-NONGST"
            nongst_bill = dict(bill_data)
            nongst_bill.update({
                'billNumber': nongst_bill_number,
                'items': nongst_items,
                'subtotal': nongst_subtotal,
                'tax': 0.0,
                'discount': 0.0,
                'total': nongst_subtotal,
                'taxType': 'NON_GST',
                'isGstSplit': True
            })
            formatted_nongst = format_bill_to_requested_schema(nongst_bill)
            nongst_success, nongst_msg = sync_nongst_bill(formatted_nongst)

            # Local JSON backup
            nongst_file_path = os.path.join(NONGST_BILLS_DIR, f"{nongst_bill_number}.json")
            with open(nongst_file_path, 'w', encoding='utf-8') as f:
                json.dump(formatted_nongst, f, indent=2, ensure_ascii=False)
            saved_files.append(f"backend/data/bills/nongst/{nongst_bill_number}.json")

            print(f"[DIRECT TABLE CONVERSION] Converted bill {base_bill_number} into Supabase tables 'gst_bills' & 'salesperson_bills'")

            if not (gst_success and nongst_success):
                return jsonify({
                    'success': False,
                    'split': True,
                    'message': 'Bill split and saved locally, but Supabase sync failed',
                    'supabaseGstStatus': gst_msg,
                    'supabaseNonGstStatus': nongst_msg
                }), 500

            return jsonify({
                'success': True,
                'split': True,
                'message': f"Converted bill directly into Supabase tables 'gst_bills' and 'salesperson_bills'",
                'supabaseGstStatus': gst_msg,
                'supabaseNonGstStatus': nongst_msg
            }), 201

        # Case 2: ONLY GST products -> Direct convert to 'gst_order_items' table
        elif len(gst_items) > 0 or float(bill_data.get('tax', 0.0)) > 0:
            bill_data['taxType'] = 'GST'
            filename = f"{base_bill_number}.json"
            file_path = os.path.join(GST_BILLS_DIR, filename)
            formatted_bill = format_bill_to_requested_schema(bill_data)
            
            # Direct Supabase table insert
            success, msg = sync_gst_bill(formatted_bill)

            # Local JSON backup
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(formatted_bill, f, indent=2, ensure_ascii=False)
            print(f"[DIRECT TABLE CONVERSION] Converted GST bill {filename} into Supabase table 'gst_bills'")
            
            if not success:
                return jsonify({
                    'success': False,
                    'split': False,
                    'dbType': 'GST',
                    'targetTable': 'gst_bills',
                    'message': 'Bill saved locally, but Supabase sync failed',
                    'supabaseStatus': msg
                }), 500

            return jsonify({
                'success': True,
                'split': False,
                'dbType': 'GST',
                'targetTable': 'gst_bills',
                'message': f"Converted bill items directly into Supabase table 'gst_bills'",
                'supabaseStatus': msg
            }), 201

        # Case 3: ONLY NON-GST products -> Direct convert to 'salesperson_bills' table
        else:
            bill_data['taxType'] = 'NON_GST'
            filename = f"{base_bill_number}.json"
            file_path = os.path.join(NONGST_BILLS_DIR, filename)
            formatted_bill = format_bill_to_requested_schema(bill_data)
            
            # Direct Supabase table insert
            success, msg = sync_nongst_bill(formatted_bill)

            # Local JSON backup
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(formatted_bill, f, indent=2, ensure_ascii=False)
            print(f"[DIRECT TABLE CONVERSION] Converted Non-GST bill {filename} into Supabase table 'salesperson_bills'")

            if not success:
                return jsonify({
                    'success': False,
                    'split': False,
                    'dbType': 'NON_GST',
                    'targetTable': 'salesperson_bills',
                    'message': 'Bill saved locally, but Supabase sync failed',
                    'supabaseStatus': msg
                }), 500

            return jsonify({
                'success': True,
                'split': False,
                'dbType': 'NON_GST',
                'targetTable': 'salesperson_bills',
                'message': f"Converted bill items directly into Supabase table 'salesperson_bills'",
                'supabaseStatus': msg
            }), 201

    except Exception as e:
        print(f"[FLASK ERROR] Failed to save bill JSON: {e}")
        return jsonify({'error': f'Failed to write bill file: {str(e)}'}), 500


@app.route('/api/bills/<bill_id>/status', methods=['PATCH'])
def update_bill_status(bill_id):
    """Updates the status of a specific bill in local JSON and syncs to Supabase."""
    try:
        data = request.get_json()
        if not data or 'status' not in data:
            return jsonify({'error': 'Missing status in request body'}), 400

        new_status = data['status']
        
        # We don't know if it's in GST or NON-GST, so we search both
        for db_dir, sync_func in [(GST_BILLS_DIR, sync_gst_bill), (NONGST_BILLS_DIR, sync_nongst_bill)]:
            if not os.path.exists(db_dir):
                continue
                
            for filename in os.listdir(db_dir):
                if not filename.endswith('.json'):
                    continue
                
                filepath = os.path.join(db_dir, filename)
                with open(filepath, 'r', encoding='utf-8') as f:
                    bill_data = json.load(f)
                
                # Check if this is the target bill
                if bill_data.get('id') == bill_id or bill_data.get('bill_id') == bill_id or bill_data.get('billNumber') == bill_id or bill_data.get('bill_no') == bill_id or filename.startswith(f"{bill_id}"):
                    # Found it! Update status
                    bill_data['status'] = new_status
                    bill_data['updated_at'] = datetime.now().isoformat()
                    
                    # Also update amount_paid if provided
                    if 'amountPaid' in data:
                        bill_data['amount_paid'] = float(data['amountPaid'])
                    
                    # Save locally
                    with open(filepath, 'w', encoding='utf-8') as f:
                        json.dump(bill_data, f, indent=2, ensure_ascii=False)
                        
                    # Sync to Supabase
                    success, msg = sync_func(bill_data)
                    
                    if not success:
                        return jsonify({
                            'success': False, 
                            'message': 'Updated locally but failed to sync to Supabase',
                            'error': msg
                        }), 500
                        
                    return jsonify({
                        'success': True,
                        'message': 'Bill status updated successfully',
                        'status': new_status
                    }), 200
                    
        return jsonify({'error': f'Bill {bill_id} not found'}), 404
        
    except Exception as e:
        print(f"[FLASK ERROR] Failed to update bill status: {e}")
        return jsonify({'error': str(e)}), 500



@app.route('/api/bills/erp_items', methods=['GET'])
def get_erp_items():
    """Returns flat array of all items matching erp_billing_system_company_items table."""
    try:
        raw_gst = read_json_files(GST_BILLS_DIR)
        raw_nongst = read_json_files(NONGST_BILLS_DIR)
        all_bills = raw_gst + raw_nongst
        
        all_erp_items = []
        for bill in all_bills:
            items = bill.get('items', [])
            all_erp_items.extend(items)

        return jsonify(all_erp_items), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/bills/array', methods=['GET'])
def get_bills_array():
    """Returns array of all bills formatted in parent bill schema (WITHOUT bill_date & bill_time)."""
    try:
        raw_gst = read_json_files(GST_BILLS_DIR)
        raw_nongst = read_json_files(NONGST_BILLS_DIR)
        all_raw = raw_gst + raw_nongst
        
        summary_list = []
        for b in all_raw:
            formatted = format_bill_to_requested_schema(b)
            summary_list.append({
                "id": formatted.get("id"),
                "submitted_by": formatted.get("submitted_by"),
                "customer_name": formatted.get("customer_name"),
                "customer_phone": formatted.get("customer_phone"),
                "payment_type": formatted.get("payment_type"),
                "sales_type": formatted.get("sales_type"),
                "price_list": formatted.get("price_list"),
                "grand_total": formatted.get("grand_total"),
                "status": formatted.get("status"),
                "created_at": formatted.get("created_at"),
                "updated_at": formatted.get("updated_at"),
                "processed_at": formatted.get("processed_at")
            })

        return jsonify(summary_list), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/bills/gst', methods=['GET'])
def get_gst_bills():
    """Retrieves all bill JSON files from the GST Database."""
    return fetch_bills_from_dir(GST_BILLS_DIR, 'GST')


@app.route('/api/bills/nongst', methods=['GET'])
def get_nongst_bills():
    """Retrieves all bill JSON files from the NON-GST Database."""
    return fetch_bills_from_dir(NONGST_BILLS_DIR, 'NON_GST')


@app.route('/api/bills', methods=['GET'])
def get_all_bills():
    """Retrieves all bills from both GST and NON-GST Databases combined."""
    try:
        gst_list = read_json_files(GST_BILLS_DIR)
        nongst_list = read_json_files(NONGST_BILLS_DIR)
        combined = gst_list + nongst_list
        combined.sort(key=lambda b: b.get('bill_no', b.get('billNumber', '')), reverse=True)

        return jsonify({
            'total': len(combined),
            'gstTotal': len(gst_list),
            'nonGstTotal': len(nongst_list),
            'bills': combined
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/products', methods=['GET'])
def get_products():
    """Retrieves active products from the Supabase products table."""
    try:
        products, err = fetch_products()
        if err:
            return jsonify({'error': err, 'products': []}), 502
        return jsonify({'total': len(products), 'products': products}), 200
    except Exception as e:
        return jsonify({'error': str(e), 'products': []}), 500


@app.route('/api/customers', methods=['GET'])
def get_customers():
    """Retrieves customer suggestions from the Supabase customers table."""
    try:
        query = request.args.get('q', '').strip()
        customers, err = fetch_customers(query)
        if err:
            return jsonify({'error': err, 'customers': []}), 502
        return jsonify({'total': len(customers), 'customers': customers}), 200
    except Exception as e:
        return jsonify({'error': str(e), 'customers': []}), 500


@app.route('/api/analytics', methods=['GET'])
def get_analytics():
    """Computes separate GST sales and NON-GST sales analytics."""
    try:
        gst_bills = read_json_files(GST_BILLS_DIR)
        nongst_bills = read_json_files(NONGST_BILLS_DIR)

        gst_sales = sum(float(b.get('grand_total', b.get('total', 0.0))) for b in gst_bills)
        nongst_sales = sum(float(b.get('grand_total', b.get('total', 0.0))) for b in nongst_bills)
        total_sales = gst_sales + nongst_sales

        total_count = len(gst_bills) + len(nongst_bills)
        avg_sales = (total_sales / total_count) if total_count > 0 else 0.0

        return jsonify({
            'totalSales': total_sales,
            'gstSales': gst_sales,
            'nonGstSales': nongst_sales,
            'totalBillCount': total_count,
            'gstBillCount': len(gst_bills),
            'nonGstBillCount': len(nongst_bills),
            'averageBillAmount': avg_sales
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


def read_json_files(target_dir):
    """Helper to read all .json files from a target directory."""
    result = []
    if os.path.exists(target_dir):
        file_list = [f for f in os.listdir(target_dir) if f.endswith('.json')]
        file_list.sort(reverse=True)
        for file_name in file_list:
            file_path = os.path.join(target_dir, file_name)
            with open(file_path, 'r', encoding='utf-8') as f:
                result.append(json.load(f))
    return result


def fetch_bills_from_dir(target_dir, db_name):
    """Helper for returning directory bills endpoint."""
    try:
        bills = read_json_files(target_dir)
        return jsonify({
            'database': db_name,
            'total': len(bills),
            'bills': bills
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    print("====================================================")
    print("Vela Billing Dual DB (GST & NON-GST) Flask Backend Active")
    print(f"GST JSON DB Folder:     {GST_BILLS_DIR}")
    print(f"NON-GST JSON DB Folder: {NONGST_BILLS_DIR}")
    print("====================================================")
    app.run(host='127.0.0.1', port=5000, debug=True)

