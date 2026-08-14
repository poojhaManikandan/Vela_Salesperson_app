-- =====================================================
-- Supabase Setup: salesperson_bills table
-- Run this script once in the Supabase SQL Editor
-- =====================================================

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

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_salesperson_bills_created_at
    ON salesperson_bills (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_salesperson_bills_customer_name
    ON salesperson_bills (customer_name);
CREATE INDEX IF NOT EXISTS idx_salesperson_bills_status
    ON salesperson_bills (status);
CREATE INDEX IF NOT EXISTS idx_salesperson_bills_salesman_id
    ON salesperson_bills (salesman_id);

-- Row Level Security: Allow authenticated users full access,
-- and allow anon key inserts for the local Flask service.
ALTER TABLE salesperson_bills ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable all for authenticated" ON salesperson_bills;
CREATE POLICY "Enable all for authenticated"
    ON salesperson_bills
    FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Enable insert for anon" ON salesperson_bills;
CREATE POLICY "Enable insert for anon"
    ON salesperson_bills
    FOR INSERT
    WITH CHECK (true);

-- Auto-update updated_at on row change
CREATE OR REPLACE FUNCTION update_salesperson_bills_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_salesperson_bills_updated_at ON salesperson_bills;
CREATE TRIGGER trg_salesperson_bills_updated_at
    BEFORE UPDATE ON salesperson_bills
    FOR EACH ROW
    EXECUTE FUNCTION update_salesperson_bills_updated_at();