-- Patients previously only recorded age in whole years, which is too
-- coarse for infants/toddlers where months matter clinically. Add an
-- age_months column (0-11) so age can be captured as years + months.
ALTER TABLE patients
  ADD COLUMN IF NOT EXISTS age_months SMALLINT
    CHECK (age_months >= 0 AND age_months <= 11);
