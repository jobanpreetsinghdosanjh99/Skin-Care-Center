-- Deleting a patient previously failed with a foreign key violation whenever
-- that patient had any prescriptions, because prescriptions.patient_id had no
-- ON DELETE behavior (defaults to RESTRICT). Deleting a patient is expected
-- to remove their prescription history too (prescription_items and
-- prescription_diseases already cascade from prescriptions), so make the
-- patient -> prescriptions link cascade as well.
ALTER TABLE prescriptions
  DROP CONSTRAINT IF EXISTS prescriptions_patient_id_fkey;

ALTER TABLE prescriptions
  ADD CONSTRAINT prescriptions_patient_id_fkey
  FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE;
