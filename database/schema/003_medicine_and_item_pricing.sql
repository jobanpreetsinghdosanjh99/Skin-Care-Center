-- Adds per-unit pricing to medicines and a price snapshot on each
-- prescription item, so prescriptions can show an itemized cost and a
-- final total amount. The prescription_items snapshot preserves the
-- price that was charged at prescribing time even if the medicine's
-- price changes later.
ALTER TABLE medicines
  ADD COLUMN IF NOT EXISTS price_per_unit NUMERIC(10, 2) NOT NULL DEFAULT 0
    CHECK (price_per_unit >= 0);

ALTER TABLE prescription_items
  ADD COLUMN IF NOT EXISTS unit_price NUMERIC(10, 2) NOT NULL DEFAULT 0
    CHECK (unit_price >= 0);
