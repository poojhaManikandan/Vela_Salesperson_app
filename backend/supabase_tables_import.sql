-- ==========================================================================
-- Supabase Import Script for Salesperson Bills
-- Target Table: salesperson_bills
-- ==========================================================================

-- ==========================================================================
-- 1. Non-GST Bills Data Inserts -> salesperson_bills
-- (GST bills are intentionally excluded: salesperson_bills holds Non-GST only)
-- ==========================================================================

-- Bill from NON-GST: INV-2026-1001-NONGST.json -> Table: salesperson_bills
INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type, sales_type, price_list, items, grand_total, status, created_at, updated_at, processed_at, salesman_id
) VALUES (
    '11cc31c3-afce-4b6a-9d95-9f4ab0b088ec', 'Unknown Cashier', NULL, 'Walk-in Customer', '', 'Cash', 'Retail', 'Retail', '[{"product_id": "P001", "product_name": "Rope", "quantity": 5, "unit_price": 20, "discount": 0, "total": 100}]'::jsonb, 100.00, 'PENDING', '2026-08-11T15:07:00.653200+05:30', '2026-08-11T15:07:00.653200+05:30', NULL, NULL
) ON CONFLICT (id) DO NOTHING;

-- Bill from NON-GST: INV-2026-1001.json -> Table: salesperson_bills
INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type, sales_type, price_list, items, grand_total, status, created_at, updated_at, processed_at, salesman_id
) VALUES (
    'a20aba05-fba0-4f69-8b55-114a1fd2ca75', 'EMP1024', NULL, 'Poojha M', '1234567', 'Cash', 'Retail', 'Retail', '[{"product_id": "P013", "product_name": "Organic Farm Eggs 6pcs (Non-GST)", "quantity": 1, "unit_price": 60, "discount": 0, "total": 60}]'::jsonb, 60.00, 'PENDING', '2026-08-11T15:51:17.937', '2026-08-11T15:51:17.937', NULL, NULL
) ON CONFLICT (id) DO NOTHING;

-- Bill from NON-GST: INV-2026-1003-NONGST.json -> Table: salesperson_bills
INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type, sales_type, price_list, items, grand_total, status, created_at, updated_at, processed_at, salesman_id
) VALUES (
    'cbec7bc8-199a-46ab-8906-c7937af62ea6', '9344486055', NULL, 'Jack', '7397572882', 'Card', 'Retail', 'Retail', '[{"product_id": "d0bc7ab1-01ff-4bbd-96cf-73f6476d78ad", "product_name": "Aero Rice 26kg", "quantity": 1, "unit_price": 1332.81, "discount": 0, "total": 1332.81}]'::jsonb, 1332.81, 'PENDING', '2026-08-12T02:55:21.655998', '2026-08-12T02:55:21.655998', NULL, NULL
) ON CONFLICT (id) DO NOTHING;

-- Bill from NON-GST: INV-2026-1003.json -> Table: salesperson_bills
INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type, sales_type, price_list, items, grand_total, status, created_at, updated_at, processed_at, salesman_id
) VALUES (
    '3d1cfb58-e2be-4208-8dad-c789eee7b8f0', 'EMP1024', NULL, 'POOJHA M', '1234566789', 'Cash', 'Retail', 'Retail', '[{"product_id": "P013", "product_name": "Organic Farm Eggs 6pcs (Non-GST)", "quantity": 1, "unit_price": 60, "discount": 0, "total": 60}]'::jsonb, 60.00, 'PENDING', '2026-08-11T15:48:43.514', '2026-08-11T15:48:43.514', NULL, NULL
) ON CONFLICT (id) DO NOTHING;

-- Bill from NON-GST: INV-2026-1004-NONGST.json -> Table: salesperson_bills
INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type, sales_type, price_list, items, grand_total, status, created_at, updated_at, processed_at, salesman_id
) VALUES (
    'cb708953-1605-4138-aa7e-24f2893e3820', '9344486055', NULL, 'Jack', '7397572882', 'Credit', 'Retail', 'Retail', '[{"product_id": "9a9909c5-7046-4380-a8ec-66f7ce30b197", "product_name": "Achu Vellam", "quantity": 1, "unit_price": 1442.7, "discount": 0, "total": 1442.7}, {"product_id": "34184071-fc3b-4231-8d6b-e7d5603cd5d6", "product_name": "Air India 26 kg 2y", "quantity": 1, "unit_price": 2015.1, "discount": 0, "total": 2015.1}]'::jsonb, 3457.80, 'PENDING', '2026-08-12T03:26:29.743955', '2026-08-12T03:26:29.743955', NULL, NULL
) ON CONFLICT (id) DO NOTHING;

-- Bill from NON-GST: INV-2026-2028-NONGST.json -> Table: salesperson_bills
INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type, sales_type, price_list, items, grand_total, status, created_at, updated_at, processed_at, salesman_id
) VALUES (
    'e2da1105-cfe8-4a11-8300-b498de4dbb76', 'Unknown Cashier', NULL, 'Walk-in Customer', '', 'Cash', 'Retail', 'Retail', '[{"product_id": "P001", "product_name": "Fresh Farm Veggies 1kg (Non-GST)", "quantity": 1, "unit_price": 85, "discount": 0, "total": 85}, {"product_id": "P002", "product_name": "Organic Farm Eggs 6pcs (Non-GST)", "quantity": 1, "unit_price": 60, "discount": 0, "total": 60}]'::jsonb, 145.00, 'PENDING', '2026-08-11T15:07:00.674742+05:30', '2026-08-11T15:07:00.674742+05:30', NULL, NULL
) ON CONFLICT (id) DO NOTHING;

-- Bill from NON-GST: INV-2026-7777-NONGST.json -> Table: salesperson_bills
INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type, sales_type, price_list, items, grand_total, status, created_at, updated_at, processed_at, salesman_id
) VALUES (
    'b4a88074-893a-43eb-8b4e-53371ebc1c7f', '9876543210', NULL, 'Mixed Order Test', '9876543210', 'Cash', 'Retail', 'Retail', '[{"product_id": "P001", "product_name": "Fresh Milk", "quantity": 2, "unit_price": 20, "discount": 0, "total": 40}]'::jsonb, 40.00, 'PENDING', '2026-08-12T12:00:00', '2026-08-12T12:00:00', NULL, NULL
) ON CONFLICT (id) DO NOTHING;

-- Bill from NON-GST: INV-2026-7779-NONGST.json -> Table: salesperson_bills
INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type, sales_type, price_list, items, grand_total, status, created_at, updated_at, processed_at, salesman_id
) VALUES (
    'ff09d1a3-2966-4a4e-8ff4-f6bc5c46330e', '9876543210', NULL, 'Walk-in Customer', '', 'Cash', 'Retail', 'Retail', '[{"product_id": "P001", "product_name": "Fresh Milk", "quantity": 2, "unit_price": 20, "discount": 0, "total": 40}]'::jsonb, 40.00, 'PENDING', '2026-08-12T14:00:00.000000+05:30', '2026-08-12T14:00:00.000000+05:30', NULL, NULL
) ON CONFLICT (id) DO NOTHING;

-- Bill from NON-GST: INV-2026-8890-NONGST.json -> Table: salesperson_bills
INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type, sales_type, price_list, items, grand_total, status, created_at, updated_at, processed_at, salesman_id
) VALUES (
    '6d7ff28e-87fd-4fdc-b164-5b75889b6cac', '9344486055', NULL, 'PayMode Test', '', 'Card', 'Retail', 'Retail', '[{"product_id": "d0bc7ab1-01ff-4bbd-96cf-73f6476d78ad", "product_name": "Aero Rice 26kg", "quantity": 1, "unit_price": 1332.81, "discount": 0, "total": 1332.81}]'::jsonb, 1332.81, 'PENDING', '2026-08-12T09:00:00+05:30', '2026-08-12T09:00:00+05:30', NULL, NULL
) ON CONFLICT (id) DO NOTHING;

-- Bill from NON-GST: INV-2026-8891-NONGST.json -> Table: salesperson_bills
INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type, sales_type, price_list, items, grand_total, status, created_at, updated_at, processed_at, salesman_id
) VALUES (
    '6dfa90f6-e603-4a4d-89dc-f9275ef98fdb', '9344486055', NULL, 'PayMode Test', '', 'UPI', 'Retail', 'Retail', '[{"product_id": "d0bc7ab1-01ff-4bbd-96cf-73f6476d78ad", "product_name": "Aero Rice 26kg", "quantity": 1, "unit_price": 1332.81, "discount": 0, "total": 1332.81}]'::jsonb, 1332.81, 'PENDING', '2026-08-12T09:00:00+05:30', '2026-08-12T09:00:00+05:30', NULL, NULL
) ON CONFLICT (id) DO NOTHING;

-- Bill from NON-GST: INV-2026-8892-NONGST.json -> Table: salesperson_bills
INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type, sales_type, price_list, items, grand_total, status, created_at, updated_at, processed_at, salesman_id
) VALUES (
    '57b0ac32-80e7-4d45-b545-e8516d3fa2e5', '9344486055', NULL, 'PayMode Test', '', 'Card', 'Retail', 'Retail', '[{"product_id": "d0bc7ab1-01ff-4bbd-96cf-73f6476d78ad", "product_name": "Aero Rice 26kg", "quantity": 1, "unit_price": 1332.81, "discount": 0, "total": 1332.81}]'::jsonb, 1332.81, 'PENDING', '2026-08-12T09:00:00+05:30', '2026-08-12T09:00:00+05:30', NULL, NULL
) ON CONFLICT (id) DO NOTHING;
