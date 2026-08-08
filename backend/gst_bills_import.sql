-- ==========================================
-- Table Definitions & Imports for GST Billing Database
-- ==========================================

CREATE TABLE IF NOT EXISTS erp_billing_system (
    bill_id UUID PRIMARY KEY,
    business_name VARCHAR(255) NOT NULL,
    bill_no VARCHAR(50) NOT NULL,
    payment_mode VARCHAR(50) DEFAULT 'CASH',
    total_items INT NOT NULL,
    total_quantity NUMERIC(10, 2) NOT NULL,
    grand_total NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS erp_billing_system_company_items (
    item_id UUID PRIMARY KEY,
    invoice_id UUID REFERENCES erp_billing_system(bill_id) ON DELETE CASCADE,
    sno INT NOT NULL,
    description VARCHAR(255) NOT NULL,
    unit VARCHAR(50) DEFAULT 'Pieces',
    quantity NUMERIC(10, 2) NOT NULL,
    rate NUMERIC(10, 2) NOT NULL,
    amount NUMERIC(10, 2) NOT NULL
);


-- ==========================================
-- GST Billing Database Insert Queries
-- ==========================================

-- Insert Bill: 2026AUG08A027 (INV-2026-2027-GST.json)
INSERT INTO erp_billing_system (
    bill_id, business_name, bill_no, payment_mode, 
    total_items, total_quantity, grand_total, created_at
) VALUES (
    'f6480fac-166e-443e-b039-7cac2dbff336', 'VELA AGENCY MAIN STORE', '2026AUG08A027', 'CASH', 
    2, 2.00, 638.40, '2026-08-08 17:50:12.166249+00'
) ON CONFLICT (bill_id) DO NOTHING;
INSERT INTO erp_billing_system_company_items (
    item_id, invoice_id, sno, description, unit, quantity, rate, amount
) VALUES 
('e475241c-2352-45ce-b146-638c34853064', 'f6480fac-166e-443e-b039-7cac2dbff336', 1, 'Basmati Rice 5kg', 'bag', 1.00, 540.00, 540.00),
('0d6207f6-164d-4def-a4bc-6c1ee7efd8f5', 'f6480fac-166e-443e-b039-7cac2dbff336', 2, 'Full Cream Milk 1L', 'pouch', 1.00, 68.00, 68.00)
ON CONFLICT (item_id) DO NOTHING;

-- Insert Bill: 2026AUG08A028 (INV-2026-2028-GST.json)
INSERT INTO erp_billing_system (
    bill_id, business_name, bill_no, payment_mode, 
    total_items, total_quantity, grand_total, created_at
) VALUES (
    '92cc3dc7-5da2-4e9f-bdc0-8a942a6cc163', 'VELA AGENCY MAIN STORE', '2026AUG08A028', 'CASH', 
    1, 1.00, 71.40, '2026-08-08 18:35:03.982674+00'
) ON CONFLICT (bill_id) DO NOTHING;
INSERT INTO erp_billing_system_company_items (
    item_id, invoice_id, sno, description, unit, quantity, rate, amount
) VALUES 
('377951dc-81da-428f-b890-560c5f0e8c65', '92cc3dc7-5da2-4e9f-bdc0-8a942a6cc163', 1, 'Full Cream Milk 1L', 'pouch', 1.00, 68.00, 68.00)
ON CONFLICT (item_id) DO NOTHING;
