import os
import json

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
NONGST_DIR = os.path.join(BASE_DIR, 'data', 'bills', 'nongst')
NONGST_SQL_FILE = os.path.join(BASE_DIR, 'nongst_bills_import.sql')


def generate_nongst_sql():
    sql_statements = []
    
    sql_statements.append("-- ==========================================")
    sql_statements.append("-- Single Unified SQL Import Script for Non-GST Bills")
    sql_statements.append("-- Target Tables: erp_sellers & erp_sellers_items")
    sql_statements.append("-- ==========================================\n")
    
    # 1. Create Parent Bills Table: erp_sellers (without bill_date & bill_time)
    sql_statements.append("""CREATE TABLE IF NOT EXISTS erp_sellers (
    bill_id UUID PRIMARY KEY,
    business_name VARCHAR(255) NOT NULL,
    bill_no VARCHAR(50) NOT NULL,
    payment_mode VARCHAR(50) DEFAULT 'CASH',
    total_items INT NOT NULL,
    total_quantity NUMERIC(10, 2) NOT NULL,
    grand_total NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
""")

    # 2. Create Items Table: erp_sellers_items
    sql_statements.append("""CREATE TABLE IF NOT EXISTS erp_sellers_items (
    item_id UUID PRIMARY KEY,
    invoice_id UUID REFERENCES erp_sellers(bill_id) ON DELETE CASCADE,
    sno INT NOT NULL,
    description VARCHAR(255) NOT NULL,
    unit VARCHAR(50) DEFAULT 'Pieces',
    quantity NUMERIC(10, 2) NOT NULL,
    rate NUMERIC(10, 2) NOT NULL,
    amount NUMERIC(10, 2) NOT NULL
);
""")

    sql_statements.append("\n-- ==========================================")
    sql_statements.append("-- Non-GST Bills & Items Data Insert Queries")
    sql_statements.append("-- ==========================================\n")

    if os.path.exists(NONGST_DIR):
        files = [f for f in os.listdir(NONGST_DIR) if f.endswith('.json')]
        for file_name in files:
            file_path = os.path.join(NONGST_DIR, file_name)
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    bill = json.load(f)

                bill_id = bill.get('bill_id')
                business_name = bill.get('business_name', 'VELA AGENCY MAIN STORE').replace("'", "''")
                bill_no = bill.get('bill_no', '')
                payment_mode = bill.get('payment_mode', 'CASH')
                total_items = bill.get('total_items', 0)
                total_quantity = bill.get('total_quantity', '0.00')
                grand_total = bill.get('grand_total', '0.00')
                created_at = bill.get('created_at', '')

                # Parent Insert Query
                parent_query = f"""INSERT INTO erp_sellers (
    bill_id, business_name, bill_no, payment_mode, 
    total_items, total_quantity, grand_total, created_at
) VALUES (
    '{bill_id}', '{business_name}', '{bill_no}', '{payment_mode}', 
    {total_items}, {total_quantity}, {grand_total}, '{created_at}'
) ON CONFLICT (bill_id) DO NOTHING;"""
                
                sql_statements.append(f"-- Insert Non-GST Bill: {bill_no} ({file_name})")
                sql_statements.append(parent_query)

                items = bill.get('items', [])
                if items:
                    item_tuples = []
                    for item in items:
                        item_id = item.get('item_id') or item.get('bill_item_id')
                        invoice_id = item.get('invoice_id') or bill_id
                        sno = item.get('sno', 1)
                        desc = item.get('description', '').replace("'", "''")
                        unit = item.get('unit', 'Pieces').replace("'", "''")
                        qty = item.get('quantity', '1.00')
                        rate = item.get('rate', '0.00')
                        amt = item.get('amount', '0.00')

                        item_tuples.append(
                            f"('{item_id}', '{invoice_id}', {sno}, '{desc}', '{unit}', {qty}, {rate}, {amt})"
                        )

                    items_query = "INSERT INTO erp_sellers_items (\n    item_id, invoice_id, sno, description, unit, quantity, rate, amount\n) VALUES \n" + ",\n".join(item_tuples) + "\nON CONFLICT (item_id) DO NOTHING;"
                    sql_statements.append(items_query)
                
                sql_statements.append("")
            except Exception as e:
                print(f"Error processing {file_name}: {e}")

    with open(NONGST_SQL_FILE, 'w', encoding='utf-8') as f:
        f.write("\n".join(sql_statements))

    print(f"Successfully generated single Non-GST SQL import file: {NONGST_SQL_FILE}")


if __name__ == '__main__':
    generate_nongst_sql()
