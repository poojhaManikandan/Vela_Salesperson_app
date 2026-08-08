import os
import json
import uuid
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable Cross-Origin Resource Sharing for Flutter Web / Desktop

# Base paths for Dual GST & NON-GST JSON Databases
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
GST_BILLS_DIR = os.path.join(BASE_DIR, 'data', 'bills', 'gst')
NONGST_BILLS_DIR = os.path.join(BASE_DIR, 'data', 'bills', 'nongst')

# Ensure both GST & NON-GST storage directories exist
os.makedirs(GST_BILLS_DIR, exist_ok=True)
os.makedirs(NONGST_BILLS_DIR, exist_ok=True)


def format_items_to_erp_schema(items, parent_bill_id):
    """
    Formats items array to match exact 'erp_billing_system_company_items' table schema from image 3:
    [
      {
        "item_id": "622079ee-eff1-49d6-bc91-0429355fb...",
        "invoice_id": "69fd93fe-1013-486c-bf1f-b20e...",
        "sno": 1,
        "description": "3 Rose 250gr",
        "unit": "Pieces",
        "quantity": "1.00",
        "rate": "207.29",
        "amount": "207.29"
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
        
        description = str(
            prod.get('description') or 
            prod.get('name') or 
            item.get('description') or 
            item.get('name') or 
            'Item'
        )
        
        # Quantity
        qty_num = float(item.get('quantity', 1))
        quantity_str = f"{qty_num:.2f}"
        
        # Rate (price per unit)
        rate_num = float(prod.get('rate') or prod.get('price') or item.get('rate') or item.get('price') or 0.0)
        rate_str = f"{rate_num:.2f}"
        
        # Amount (rate * quantity)
        amount_num = float(item.get('amount', rate_num * qty_num))
        amount_str = f"{amount_num:.2f}"
        
        # Unit (e.g. Pieces, Nos, pack, etc.)
        unit_str = str(prod.get('unit') or item.get('unit') or 'Pieces')
        if unit_str.lower() in ['pcs', 'piece', 'item']:
            unit_str = 'Pieces'
        
        # item_id (UUID) & invoice_id (Parent bill_id)
        item_id = item.get('item_id') or item.get('bill_item_id') or str(uuid.uuid4())
        invoice_id = item.get('invoice_id') or parent_bill_id

        formatted_items.append({
            "item_id": item_id,
            "invoice_id": invoice_id,
            "sno": idx,
            "description": description,
            "unit": unit_str,
            "quantity": quantity_str,
            "rate": rate_str,
            "amount": amount_str
        })
        
    return formatted_items


def format_bill_to_requested_schema(bill_data):
    """
    Transforms any bill data payload into requested parent bill schema WITHOUT bill_date and bill_time.
    """
    if not isinstance(bill_data, dict):
        return bill_data

    bill_id = bill_data.get('bill_id') or str(uuid.uuid4())
    business_name = str(bill_data.get('business_name') or bill_data.get('shopName', 'VELA AGENCY')).upper()

    now = datetime.now()
    date_obj = now
    date_raw = bill_data.get('date') or bill_data.get('bill_date')
    if date_raw:
        try:
            clean_str = str(date_raw).replace('Z', '')
            if 'T' in clean_str:
                date_obj = datetime.fromisoformat(clean_str)
            else:
                time_part = bill_data.get('bill_time', '00:00:00')
                date_obj = datetime.strptime(f"{clean_str} {time_part}", '%Y-%m-%d %H:%M:%S')
        except Exception:
            date_obj = now

    raw_bill_no = str(bill_data.get('bill_no') or bill_data.get('billNumber', ''))
    if 'A' in raw_bill_no and len(raw_bill_no) >= 12:
        formatted_bill_no = raw_bill_no
    else:
        digits = ''.join([c for c in raw_bill_no if c.isdigit()])
        suffix = digits[-3:] if len(digits) >= 3 else (digits.zfill(3) if digits else '101')
        month_code = date_obj.strftime('%b').upper()
        day_code = date_obj.strftime('%d')
        year_code = date_obj.strftime('%Y')
        formatted_bill_no = f"{year_code}{month_code}{day_code}A{suffix}"

    payment_mode = str(bill_data.get('payment_mode') or bill_data.get('paymentMode', 'CASH')).upper()

    raw_items = bill_data.get('items', [])
    formatted_items = format_items_to_erp_schema(raw_items, bill_id)

    total_items = int(bill_data.get('total_items', len(formatted_items)))
    total_qty_num = sum(float(it['quantity']) for it in formatted_items) if formatted_items else float(bill_data.get('total_quantity', 1.0))
    total_quantity_str = f"{total_qty_num:.2f}"

    grand_total_num = float(bill_data.get('grand_total') or bill_data.get('total', 0.0))
    grand_total_str = f"{grand_total_num:.2f}"

    created_at = bill_data.get('created_at') or now.strftime('%Y-%m-%d %H:%M:%S.%f+00')

    formatted = {
        "bill_id": bill_id,
        "business_name": business_name,
        "bill_no": formatted_bill_no,
        "payment_mode": payment_mode,
        "total_items": total_items,
        "total_quantity": total_quantity_str,
        "grand_total": grand_total_str,
        "created_at": created_at,
        "items": formatted_items
    }

    if 'taxType' in bill_data or 'tax_type' in bill_data:
        formatted['tax_type'] = bill_data.get('taxType') or bill_data.get('tax_type')

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

        gst_items = []
        nongst_items = []

        for item in items:
            prod = item.get('product', {}) if isinstance(item.get('product'), dict) else item
            if prod.get('isGst') is not False:
                gst_items.append(item)
            else:
                nongst_items.append(item)

        def compute_subtotal(item_list):
            sub = 0.0
            for it in item_list:
                p = it.get('product', {}) if isinstance(it.get('product'), dict) else it
                price = float(p.get('price') or p.get('rate') or 0.0)
                qty = int(it.get('quantity', 1))
                sub += price * qty
            return round(sub, 2)

        saved_files = []

        # Case 1: Mixed Transaction -> SPLIT INTO 2 JSON FILES!
        if len(gst_items) > 0 and len(nongst_items) > 0:
            # 1. Create GST Bill JSON
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
            gst_file_path = os.path.join(GST_BILLS_DIR, f"{gst_bill_number}.json")
            with open(gst_file_path, 'w', encoding='utf-8') as f:
                json.dump(formatted_gst, f, indent=2, ensure_ascii=False)
            saved_files.append(f"backend/data/bills/gst/{gst_bill_number}.json")
            print(f"[SPLIT GST DB STORED] Saved {gst_bill_number}.json in backend/data/bills/gst/")

            # 2. Create NON-GST Bill JSON
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
            nongst_file_path = os.path.join(NONGST_BILLS_DIR, f"{nongst_bill_number}.json")
            with open(nongst_file_path, 'w', encoding='utf-8') as f:
                json.dump(formatted_nongst, f, indent=2, ensure_ascii=False)
            saved_files.append(f"backend/data/bills/nongst/{nongst_bill_number}.json")
            print(f"[SPLIT NON-GST DB STORED] Saved {nongst_bill_number}.json in backend/data/bills/nongst/")

            return jsonify({
                'success': True,
                'split': True,
                'message': f"Split mixed transaction into 2 separate JSON files ({gst_bill_number}.json & {nongst_bill_number}.json)",
                'savedFiles': saved_files
            }), 201

        # Case 2: ONLY GST products
        elif len(gst_items) > 0 or float(bill_data.get('tax', 0.0)) > 0:
            bill_data['taxType'] = 'GST'
            filename = f"{base_bill_number}.json"
            file_path = os.path.join(GST_BILLS_DIR, filename)
            formatted_bill = format_bill_to_requested_schema(bill_data)
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(formatted_bill, f, indent=2, ensure_ascii=False)
            print(f"[GST DB STORED] Saved {filename} in backend/data/bills/gst/")
            return jsonify({
                'success': True,
                'split': False,
                'dbType': 'GST',
                'message': f"Bill stored in GST database as {filename}",
                'filePath': f"backend/data/bills/gst/{filename}"
            }), 201

        # Case 3: ONLY NON-GST products
        else:
            bill_data['taxType'] = 'NON_GST'
            filename = f"{base_bill_number}.json"
            file_path = os.path.join(NONGST_BILLS_DIR, filename)
            formatted_bill = format_bill_to_requested_schema(bill_data)
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(formatted_bill, f, indent=2, ensure_ascii=False)
            print(f"[NON-GST DB STORED] Saved {filename} in backend/data/bills/nongst/")
            return jsonify({
                'success': True,
                'split': False,
                'dbType': 'NON_GST',
                'message': f"Bill stored in NON-GST database as {filename}",
                'filePath': f"backend/data/bills/nongst/{filename}"
            }), 201

    except Exception as e:
        print(f"[FLASK ERROR] Failed to save bill JSON: {e}")
        return jsonify({'error': f'Failed to write bill file: {str(e)}'}), 500


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
                "bill_id": formatted.get("bill_id"),
                "business_name": formatted.get("business_name"),
                "bill_no": formatted.get("bill_no"),
                "payment_mode": formatted.get("payment_mode"),
                "total_items": formatted.get("total_items"),
                "total_quantity": formatted.get("total_quantity"),
                "grand_total": formatted.get("grand_total"),
                "created_at": formatted.get("created_at")
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
