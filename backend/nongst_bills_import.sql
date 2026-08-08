-- ==========================================
-- Table Definitions for Non-GST Billing System (Without date & time)
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
-- Non-GST Bills & Items Data Insert Queries
-- ==========================================

-- Insert Non-GST Bill: 2026AUG08A027 (INV-2026-2027-NONGST.json)
INSERT INTO erp_billing_system (
    bill_id, business_name, bill_no, payment_mode, 
    total_items, total_quantity, grand_total, created_at
) VALUES (
    '0a766c8b-ca4b-4a52-9044-4bbdc1152031', 'VELA AGENCY MAIN STORE', '2026AUG08A027', 'CASH', 
    2, 2.00, 145.00, '2026-08-08 17:50:12.168370+00'
) ON CONFLICT (bill_id) DO NOTHING;
INSERT INTO erp_billing_system_company_items (
    item_id, invoice_id, sno, description, unit, quantity, rate, amount
) VALUES 
('bc34db06-c796-4832-8bf9-efba7c787c6b', '0a766c8b-ca4b-4a52-9044-4bbdc1152031', 1, 'Organic Farm Eggs 6pcs (Non-GST)', 'pack', 1.00, 60.00, 60.00),
('2c858f8f-6200-4cd0-8cf1-115bf2ca1ecc', '0a766c8b-ca4b-4a52-9044-4bbdc1152031', 2, 'Fresh Farm Veggies 1kg (Non-GST)', 'pack', 1.00, 85.00, 85.00)
ON CONFLICT (item_id) DO NOTHING;
