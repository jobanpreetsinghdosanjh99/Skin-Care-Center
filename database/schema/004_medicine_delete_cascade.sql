-- Deleting a medicine previously failed with a foreign key violation as
-- soon as it had any stock history, because stock_movements.medicine_id
-- had no ON DELETE behavior (defaults to RESTRICT) -- and effectively
-- every medicine gets a stock_movements row the moment it's created
-- (the "Initial stock" opening balance).
--
-- A medicine's own stock ledger is specific to that medicine, so it's
-- safe (and expected) to cascade-delete it along with the medicine.
--
-- prescription_items.medicine_id is different: it's a soft link used for
-- decrementing live stock, but each item already stores its own
-- medicine_name/dosage/unit_price as a historical snapshot. Deleting the
-- medicine should NOT delete/hide past prescriptions, so that FK is
-- changed to SET NULL instead of cascading.
ALTER TABLE stock_movements
  DROP CONSTRAINT IF EXISTS stock_movements_medicine_id_fkey;

ALTER TABLE stock_movements
  ADD CONSTRAINT stock_movements_medicine_id_fkey
  FOREIGN KEY (medicine_id) REFERENCES medicines(id) ON DELETE CASCADE;

ALTER TABLE prescription_items
  DROP CONSTRAINT IF EXISTS prescription_items_medicine_id_fkey;

ALTER TABLE prescription_items
  ADD CONSTRAINT prescription_items_medicine_id_fkey
  FOREIGN KEY (medicine_id) REFERENCES medicines(id) ON DELETE SET NULL;
