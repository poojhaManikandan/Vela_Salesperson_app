-- =====================================================
-- Supabase Setup: gst_bills table
-- Same columns as salesperson_bills, PLUS a "gst" column
-- that stores the GST tax amount for the bill.
-- Run this script once in the Supabase SQL Editor.
-- =====================================================

CREATE TABLE IF NOT EXISTS gst_bills (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submitted_by   TEXT NOT NULL DEFAULT '',
    customer_name  VARCHAR(150) NOT NULL DEFAULT 'Walk-in Customer',
    customer_phone VARCHAR(20) NOT NULL DEFAULT '',
    payment_type   VARCHAR(30) NOT NULL DEFAULT 'Cash',
    sales_type     VARCHAR(30) NOT NULL DEFAULT 'Retail',
    price_list     VARCHAR(30) NOT NULL DEFAULT 'Retail',
    items          JSONB NOT NULL DEFAULT '[]',
    grand_total    NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    status         TEXT NOT NULL DEFAULT 'PENDING',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at   TIMESTAMPTZ,
    salesman_id    INTEGER NOT NULL DEFAULT 0,
    customer_id    UUID,
    gst            NUMERIC(10, 2) NOT NULL DEFAULT 0.00
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_gst_bills_created_at
    ON gst_bills (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_gst_bills_customer_name
    ON gst_bills (customer_name);
CREATE INDEX IF NOT EXISTS idx_gst_bills_status
    ON gst_bills (status);
CREATE INDEX IF NOT EXISTS idx_gst_bills_salesman_id
    ON gst_bills (salesman_id);

-- Row Level Security: same policy approach as salesperson_bills.
ALTER TABLE gst_bills ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable all for authenticated" ON gst_bills;
CREATE POLICY "Enable all for authenticated"
    ON gst_bills
    FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Enable insert for anon" ON gst_bills;
CREATE POLICY "Enable insert for anon"
    ON gst_bills
    FOR INSERT
    WITH CHECK (true);

-- Auto-update updated_at on row change
CREATE OR REPLACE FUNCTION update_gst_bills_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_gst_bills_updated_at ON gst_bills;
CREATE TRIGGER trg_gst_bills_updated_at
    BEFORE UPDATE ON gst_bills
    FOR EACH ROW
    EXECUTE FUNCTION update_gst_bills_updated_at();
