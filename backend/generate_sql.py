import os
import json

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
GST_DIR = os.path.join(BASE_DIR, 'data', 'bills', 'gst')
NONGST_DIR = os.path.join(BASE_DIR, 'data', 'bills', 'nongst')

NONGST_SQL_FILE = os.path.join(BASE_DIR, 'nongst_bills_import.sql')
GST_SQL_FILE = os.path.join(BASE_DIR, 'gst_bills_import.sql')


def generate_sql_file(json_dir, output_file, parent_table, items_table, title):
    sql_statements = []
    
    sql_statements.append(f"-- ==========================================")
    sql_statements.append(f"-- Table Definitions & Imports for {title}")
    sql_statements.append(f"-- ==========================================\n")
    
    # Parent Table Definition
    sql_statements.append(f"""CREATE TABLE IF NOT EXISTS {parent_table} (
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

    # Items Table Definition
    sql_statements.append(f"""CREATE TABLE IF NOT EXISTS {items_table} (
    item_id UUID PRIMARY KEY,
    invoice_id UUID REFERENCES {parent_table}(bill_id) ON DELETE CASCADE,
    sno INT NOT NULL,
    description VARCHAR(255) NOT NULL,
    unit VARCHAR(50) DEFAULT 'Pieces',
    quantity NUMERIC(10, 2) NOT NULL,
    rate NUMERIC(10, 2) NOT NULL,
    amount NUMERIC(10, 2) NOT NULL
);
""")

    sql_statements.append(f"\n-- ==========================================")
    sql_statements.append(f"-- {title} Insert Queries")
    sql_statements.append(f"-- ==========================================\n")

    if os.path.exists(json_dir):
        files = [f for f in os.listdir(json_dir) if f.endswith('.json')]
        for file_name in files:
            file_path = os.path.join(json_dir, file_name)
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
                parent_query = f"""INSERT INTO {parent_table} (
    bill_id, business_name, bill_no, payment_mode, 
    total_items, total_quantity, grand_total, created_at
) VALUES (
    '{bill_id}', '{business_name}', '{bill_no}', '{payment_mode}', 
    {total_items}, {total_quantity}, {grand_total}, '{created_at}'
) ON CONFLICT (bill_id) DO NOTHING;"""
                
                sql_statements.append(f"-- Insert Bill: {bill_no} ({file_name})")
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

                    items_query = f"INSERT INTO {items_table} (\n    item_id, invoice_id, sno, description, unit, quantity, rate, amount\n) VALUES \n" + ",\n".join(item_tuples) + "\nON CONFLICT (item_id) DO NOTHING;"
                    sql_statements.append(items_query)
                
                sql_statements.append("")
            except Exception as e:
                print(f"Error processing {file_name}: {e}")

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("\n".join(sql_statements))

    print(f"Successfully generated {title} SQL import file: {output_file}")


def main():
    # 1. Generate Non-GST SQL Import File (Target tables: erp_sellers & erp_sellers_items)
    generate_sql_file(
        json_dir=NONGST_DIR,
        output_file=NONGST_SQL_FILE,
        parent_table="erp_sellers",
        items_table="erp_sellers_items",
        title="Non-GST Billing Database"
    )

    # 2. Generate GST SQL Import File (Target tables: erp_billing_system & erp_billing_system_company_items)
    generate_sql_file(
        json_dir=GST_DIR,
        output_file=GST_SQL_FILE,
        parent_table="erp_billing_system",
        items_table="erp_billing_system_company_items",
        title="GST Billing Database"
    )


if __name__ == '__main__':
    main()
