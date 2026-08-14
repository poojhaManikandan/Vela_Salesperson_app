-- ==========================================
-- SQL Import Script for Non-GST Bills
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
-- Non-GST Bills & Items Data Insert Queries
-- ==========================================

-- Insert Bill: INV-2026-1001-NONGST.json
INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type,
    sales_type, price_list, items, grand_total, status, created_at, updated_at,
    processed_at, salesman_id
) VALUES (
    '11cc31c3-afce-4b6a-9d95-9f4ab0b088ec', '', NULL, 'Walk-in Customer', '', 'CASH',
    'Retail', '', '[{"product_id": "P001", "product_name": "Rope", "quantity": 5.0, "unit_price": 20.0, "discount": 0.0, "total": 100.0}]'::jsonb, 100.00, 'pending',
    '2026-08-11T15:07:00.653200+05:30', '2026-08-11T15:07:00.653200+05:30', NULL, NULL
) ON CONFLICT (id) DO NOTHING;

-- Insert Bill: INV-2026-2028-NONGST.json
INSERT INTO salesperson_bills (
    id, submitted_by, customer_id, customer_name, customer_phone, payment_type,
    sales_type, price_list, items, grand_total, status, created_at, updated_at,
    processed_at, salesman_id
) VALUES (
    'e2da1105-cfe8-4a11-8300-b498de4dbb76', '', NULL, 'Walk-in Customer', '', 'CASH',
    'Retail', '', '[{"product_id": "P001", "product_name": "Fresh Farm Veggies 1kg (Non-GST)", "quantity": 1.0, "unit_price": 85.0, "discount": 0.0, "total": 85.0}, {"product_id": "P002", "product_name": "Organic Farm Eggs 6pcs (Non-GST)", "quantity": 1.0, "unit_price": 60.0, "discount": 0.0, "total": 60.0}]'::jsonb, 145.00, 'pending',
    '2026-08-11T15:07:00.674742+05:30', '2026-08-11T15:07:00.674742+05:30', NULL, NULL
) ON CONFLICT (id) DO NOTHING;
