import sys
import os
import json

BASE_DIR = r"c:\Users\poojh\Downloads\vela-billing-for-seller (1)\vela-billing-for-seller\backend"
sys.path.append(BASE_DIR)

from supabase_service import push_bill_to_supabase

dummy_data = {
    "id": "5c2b3b90-1439-4c4a-b1c4-409a5661171b",
    "submitted_by": "PremKumar",
    "customer_name": "hari",
    "customer_phone": "8072827232",
    "payment_type": "UPI",
    "sales_type": "Wholesale",
    "price_list": "Wholesale Price",
    "items": [
        {
            "total": 1276.34,
            "discount": 0,
            "quantity": 1,
            "product_id": "007cacd6-d750-481e-9254-b262563458f7",
            "unit_price": 1276.34,
            "product_name": "Pattai Kudal"
        },
        {
            "total": 221.1,
            "discount": 0,
            "quantity": 1,
            "product_id": "014045b9-20ef-4ab8-b5e9-ec0a66f340ec",
            "unit_price": 221.1,
            "product_name": "Nijam Pakku"
        }
    ],
    "grand_total": 1497.44,
    "status": "PENDING",
    "created_at": "2026-08-13T09:46:29.135616+00:00",
    "updated_at": "2026-08-13T09:46:29.135616+00:00",
    "processed_at": None,
    "salesman_id": "1",
    "customer_id": "fede26fe-280c-41e5-871b-297dd3719f03"
}

print("Testing push to salesperson_bills table in Supabase...")
success, msg = push_bill_to_supabase(dummy_data, table='salesperson_bills')
if success:
    print(f"\nSUCCESS! Data successfully inserted: {msg}")
else:
    print(f"\nFAILED! Error inserting data: {msg}")
