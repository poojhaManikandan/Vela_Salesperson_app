import requests
import json

url = "http://127.0.0.1:5000/api/bills"
payload = {
    "id": None,
    "billNumber": "INV-TEST-9999",
    "submitted_by": "TestUser",
    "customer_id": None,
    "customer_name": "Test Customer",
    "customer_phone": "1234567890",
    "payment_type": "Cash",
    "sales_type": "Retail",
    "price_list": "",
    "items": [
        {
            "product_id": "P001",
            "product_name": "Test Product",
            "quantity": 1,
            "unit_price": 100.0,
            "discount": 0,
            "total": 100.0,
            "isGst": False
        }
    ],
    "grand_total": 100.0,
    "amount_paid": 0.0,
    "status": "Pending",
    "created_at": "2026-08-14T09:00:00.000",
    "updated_at": "2026-08-14T09:00:00.000",
    "processed_at": None,
    "salesman_id": None
}

print(f"Sending POST request to {url}...")
try:
    response = requests.post(url, json=payload, timeout=5)
    print(f"Status Code: {response.status_code}")
    print(f"Response Body: {response.text}")
except Exception as e:
    print(f"Failed to connect to backend: {e}")
