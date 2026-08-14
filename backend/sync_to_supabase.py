import os
import json
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from supabase_service import (
    sync_nongst_bill,
    extract_bill_row,
    is_supabase_configured
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
GST_DIR = os.path.join(BASE_DIR, 'data', 'bills', 'gst')
NONGST_DIR = os.path.join(BASE_DIR, 'data', 'bills', 'nongst')
SQL_OUTPUT_FILE = os.path.join(BASE_DIR, 'supabase_tables_import.sql')


def generate_supabase_sql():
    """Generates SQL import script matching the exact Supabase schema for salesperson_bills."""
    sql_lines = []
    sql_lines.append("-- ==========================================================================")
    sql_lines.append("-- Supabase Import Script for Salesperson Bills")
    sql_lines.append("-- Target Table: salesperson_bills")
    sql_lines.append("-- ==========================================================================\n")

    def build_insert_statements(target_dir, dir_name):
        statements = []
        if not os.path.exists(target_dir):
            return statements

        files = [f for f in os.listdir(target_dir) if f.endswith('.json')]
        files.sort()

        for file_name in files:
            file_path = os.path.join(target_dir, file_name)
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    bill_data = json.load(f)

                row = extract_bill_row(bill_data)
                if not row:
                    continue

                statements.append(f"-- Bill from {dir_name}: {file_name} -> Table: salesperson_bills")
                items_clean = row['items'].replace("'", "''")
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

                query = (
                    f"INSERT INTO salesperson_bills (\n"
                    f"    id, submitted_by, customer_id, customer_name, customer_phone, payment_type, sales_type, price_list, items, grand_total, status, created_at, updated_at, processed_at, salesman_id\n"
                    f") VALUES (\n"
                    f"    '{row['id']}', '{sub_by}', {cust_id}, '{cname}', '{row['customer_phone']}', '{payment}', "
                    f"'{s_type}', '{p_list}', '{items_clean}'::jsonb, {row['grand_total']:.2f}, '{status}', "
                    f"{created_at}, {updated_at}, {processed_at}, {salesman_id}\n"
                    f") ON CONFLICT (id) DO NOTHING;\n"
                )
                statements.append(query)
            except Exception as e:
                print(f"[SQL GEN ERROR] File {file_name}: {e}")

        return statements

    sql_lines.append("-- ==========================================================================")
    sql_lines.append("-- 1. Non-GST Bills Data Inserts -> salesperson_bills")
    sql_lines.append("-- (GST bills are intentionally excluded: salesperson_bills holds Non-GST only)")
    sql_lines.append("-- ==========================================================================\n")
    sql_lines.extend(build_insert_statements(NONGST_DIR, 'NON-GST'))

    with open(SQL_OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write("\n".join(sql_lines))

    print(f"[SQL GENERATED] Successfully written SQL script to: {SQL_OUTPUT_FILE}")


def sync_nongst_file(file_path, file_name):
    """Syncs a single Non-GST bill file to Supabase. Returns (file_name, success, msg)."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            bill_data = json.load(f)
        success, msg = sync_nongst_bill(bill_data)
        return file_name, success, msg
    except Exception as e:
        return file_name, False, str(e)


def sync_all_files(max_workers=None):
    """Scans local GST & Non-GST directories and syncs all JSON files to salesperson_bills via API."""
    print("==================================================")
    print("Syncing Local JSON Bill Files to Supabase (salesperson_bills)")
    print("==================================================")

    # 1. GST JSON Files - NOT pushed to salesperson_bills (that table holds Non-GST bills only)
    if os.path.exists(GST_DIR):
        gst_files = [f for f in os.listdir(GST_DIR) if f.endswith('.json')]
        print(f"Found {len(gst_files)} GST bill file(s) in {GST_DIR}")
        print("Skipping GST files: 'salesperson_bills' must hold Non-GST bills only.")

    # 2. Sync Non-GST JSON Files (concurrently, since each is an independent network call)
    if os.path.exists(NONGST_DIR):
        nongst_files = [f for f in os.listdir(NONGST_DIR) if f.endswith('.json')]
        print(f"\nFound {len(nongst_files)} Non-GST bill file(s) in {NONGST_DIR}")

        workers = max_workers or min(len(nongst_files), 8)
        print(f"Syncing with up to {workers} concurrent worker thread(s)...")

        with ThreadPoolExecutor(max_workers=workers) as executor:
            futures = {
                executor.submit(sync_nongst_file, os.path.join(NONGST_DIR, file_name), file_name): file_name
                for file_name in nongst_files
            }
            for future in as_completed(futures):
                file_name, success, msg = future.result()
                status = "SUCCESS" if success else "ERROR"
                print(f"  -> Non-GST File '{file_name}' [{status}]: {msg}")

    # 3. Generate SQL Script
    generate_supabase_sql()
    print("==================================================")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Sync JSON bills to Supabase table salesperson_bills.")
    parser.add_argument('--generate-sql', action='store_true', help="Only generate SQL import file.")
    parser.add_argument('--workers', type=int, default=None, help="Max concurrent sync threads (default: up to 8).")
    args = parser.parse_args()

    if args.generate_sql:
        generate_supabase_sql()
    else:
        sync_all_files(max_workers=args.workers)