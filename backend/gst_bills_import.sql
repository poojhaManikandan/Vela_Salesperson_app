-- ==========================================
-- SQL Import Script for GST Bills
-- Target Table: salesperson_bills
-- ==========================================

CREATE TABLE IF NOT EXISTS salesperson_bills (
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


-- ==========================================
-- GST Bills & Items Data Insert Queries
-- ==========================================

-- Insert Bill: INV-2026-1001-GST.json
INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type,
    sales_type, price_list, items, grand_total, status, created_at, updated_at,
    processed_at, salesman_id
) VALUES (
    'a4b45b16-2c27-43e2-bfe4-97a3ac91f6c3', '', NULL, 'Walk-in Customer', '', 'CASH',
    'Retail', '', '[{"product_id": "P001", "product_name": "Surf Excel 1kg", "quantity": 2.0, "unit_price": 125.0, "discount": 0.0, "total": 250.0}]'::jsonb, 262.50, 'pending',
    '2026-08-11T15:07:00.270263+05:30', '2026-08-11T15:07:00.270263+05:30', NULL, NULL
) ON CONFLICT (id) DO NOTHING;

-- Insert Bill: INV-2026-2028-GST.json
INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type,
    sales_type, price_list, items, grand_total, status, created_at, updated_at,
    processed_at, salesman_id
) VALUES (
    '8bdacd52-3353-4d8e-868b-4a58710191c7', '', NULL, 'Walk-in Customer', '', 'CASH',
    'Retail', '', '[{"product_id": "P001", "product_name": "Laundry Detergent 1kg", "quantity": 1.0, "unit_price": 195.0, "discount": 0.0, "total": 195.0}, {"product_id": "P002", "product_name": "Dish Wash Liquid", "quantity": 1.0, "unit_price": 110.0, "discount": 0.0, "total": 110.0}]'::jsonb, 320.25, 'pending',
    '2026-08-11T15:07:00.576748+05:30', '2026-08-11T15:07:00.576748+05:30', NULL, NULL
) ON CONFLICT (id) DO NOTHING;
