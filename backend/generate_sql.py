import os
import json
import uuid

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
GST_DIR = os.path.join(BASE_DIR, 'data', 'bills', 'gst')
NONGST_DIR = os.path.join(BASE_DIR, 'data', 'bills', 'nongst')
GST_SQL_FILE = os.path.join(BASE_DIR, 'gst_bills_import.sql')
NONGST_SQL_FILE = os.path.join(BASE_DIR, 'nongst_bills_import.sql')


def format_items(bill):
    """Maps bill items into the salesperson_bills items jsonb shape."""
    formatted = []
    for idx, item in enumerate(bill.get('items', []), start=1):
        if not isinstance(item, dict):
            continue
        formatted.append({
            "product_id": str(item.get('product_id') or f"P{idx:03d}"),
            "product_name": str(item.get('product_name') or item.get('description') or 'Item'),
            "quantity": float(item.get('quantity', 1)),
            "unit_price": float(item.get('unit_price') or item.get('rate') or item.get('price') or 0.0),
            "discount": float(item.get('discount') or item.get('discount_percent') or 0.0),
            "total": float(item.get('total') or item.get('amount') or 0.0)
        })
    return formatted


def bill_to_row(bill):
    """Maps a bill JSON file into the salesperson_bills row fields."""
    return {
        "id": str(bill.get('id') or bill.get('bill_id') or uuid.uuid4()),
        "submitted_by": str(bill.get('submitted_by') or ''),
        "customer_id": str(bill.get('customer_id')) if bill.get('customer_id') else None,
        "customer_name": str(bill.get('customer_name') or 'Walk-in Customer'),
        "customer_phone": str(bill.get('customer_phone') or ''),
        "payment_type": str(bill.get('payment_type') or bill.get('payment_mode') or 'CASH'),
        "sales_type": str(bill.get('sales_type') or 'Retail'),
        "price_list": str(bill.get('price_list') or ''),
        "items": format_items(bill),
        "grand_total": float(bill.get('grand_total') or bill.get('total') or 0.0),
        "status": str(bill.get('status') or 'pending').lower(),
        "created_at": str(bill.get('created_at') or ''),
        "updated_at": str(bill.get('updated_at') or bill.get('created_at') or ''),
        "processed_at": str(bill.get('processed_at')) if bill.get('processed_at') else None,
        "salesman_id": str(bill.get('salesman_id')) if bill.get('salesman_id') else None
    }


def build_sql_file(target_dir, sql_file, header, dir_name):
    sql_statements = []
    sql_statements.append("-- ==========================================")
    sql_statements.append(f"-- {header}")
    sql_statements.append("-- Target Table: salesperson_bills")
    sql_statements.append("-- ==========================================\n")

    sql_statements.append("""CREATE TABLE IF NOT EXISTS salesperson_bills (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submitted_by   TEXT,
    customer_id    UUID,
    customer_name  VARCHAR(255) NOT NULL,
    customer_phone VARCHAR(20),
    payment_type   VARCHAR(20) NOT NULL DEFAULT 'CASH',
    sales_type     VARCHAR(20) NOT NULL DEFAULT 'RETAIL',
    price_list     VARCHAR(100),
    items          JSONB NOT NULL DEFAULT '[]',
    grand_total    NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    status         TEXT NOT NULL DEFAULT 'pending',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at   TIMESTAMPTZ,
    salesman_id    UUID
);
""")

    sql_statements.append("\n-- ==========================================")
    sql_statements.append(f"-- {dir_name} Bills & Items Data Insert Queries")
    sql_statements.append("-- ==========================================\n")

    if os.path.exists(target_dir):
        files = [f for f in os.listdir(target_dir) if f.endswith('.json')]
        files.sort()
        for file_name in files:
            file_path = os.path.join(target_dir, file_name)
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    bill = json.load(f)

                row = bill_to_row(bill)
                items_json = json.dumps(row['items'], ensure_ascii=False).replace("'", "''")
                cname = row['customer_name'].replace("'", "''")
                sub_by = (row['submitted_by'] or '').replace("'", "''")
                payment = (row['payment_type'] or 'CASH').replace("'", "''")
                s_type = (row['sales_type'] or 'Retail').replace("'", "''")
                p_list = (row['price_list'] or '').replace("'", "''")
                status = (row['status'] or 'pending').replace("'", "''")

                cust_id = f"'{row['customer_id']}'" if row.get('customer_id') else 'NULL'
                salesman_id = f"'{row['salesman_id']}'" if row.get('salesman_id') else 'NULL'
                processed_at = f"'{row['processed_at']}'" if row.get('processed_at') else 'NULL'
                created_at = f"'{row['created_at']}'" if row.get('created_at') else 'CURRENT_TIMESTAMP'
                updated_at = f"'{row['updated_at']}'" if row.get('updated_at') else 'CURRENT_TIMESTAMP'

                query = f"""INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type,
    sales_type, price_list, items, grand_total, status, created_at, updated_at,
    processed_at, salesman_id
) VALUES (
    '{row['id']}', '{sub_by}', {cust_id}, '{cname}', '{row['customer_phone']}', '{payment}',
    '{s_type}', '{p_list}', '{items_json}'::jsonb, {row['grand_total']:.2f}, '{status}',
    {created_at}, {updated_at}, {processed_at}, {salesman_id}
) ON CONFLICT (id) DO NOTHING;"""

                sql_statements.append(f"-- Insert Bill: {file_name}")
                sql_statements.append(query)
                sql_statements.append("")
            except Exception as e:
                print(f"Error processing {file_name}: {e}")

    with open(sql_file, 'w', encoding='utf-8') as f:
        f.write("\n".join(sql_statements))

    print(f"Successfully generated SQL import file: {sql_file}")


def generate_all_sql():
    build_sql_file(GST_DIR, GST_SQL_FILE, 'SQL Import Script for GST Bills', 'GST')
    build_sql_file(NONGST_DIR, NONGST_SQL_FILE, 'SQL Import Script for Non-GST Bills', 'Non-GST')


if __name__ == '__main__':
    generate_all_sql()