CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE user_role AS ENUM ('admin', 'doctor', 'receptionist', 'inventory_staff');
CREATE TYPE gender AS ENUM ('male', 'female', 'other', 'prefer_not_to_say');
CREATE TYPE medicine_form AS ENUM (
  'cream', 'soap', 'tablet', 'capsule', 'lotion', 'sunscreen', 'face_wash',
  'serum', 'shampoo', 'syrup', 'injection', 'other'
);
CREATE TYPE prescription_status AS ENUM ('draft', 'finalized', 'cancelled');
CREATE TYPE stock_movement_type AS ENUM ('opening_balance', 'adjustment', 'prescription', 'purchase', 'return', 'correction');

CREATE TABLE clinics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  prescription_footer_note TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id),
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role user_role NOT NULL DEFAULT 'doctor',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id),
  patient_number TEXT NOT NULL,
  full_name TEXT NOT NULL,
  date_of_birth DATE,
  age_years SMALLINT CHECK (age_years >= 0 AND age_years <= 150),
  age_months SMALLINT CHECK (age_months >= 0 AND age_months <= 11),
  gender gender NOT NULL DEFAULT 'prefer_not_to_say',
  phone TEXT NOT NULL,
  address TEXT,
  allergies TEXT,
  medical_history TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (clinic_id, patient_number)
);
CREATE INDEX patients_clinic_name_idx ON patients (clinic_id, full_name);
CREATE INDEX patients_clinic_phone_idx ON patients (clinic_id, phone);

CREATE TABLE diseases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id),
  short_name TEXT NOT NULL,
  full_name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (clinic_id, short_name)
);

CREATE TABLE medicines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id),
  name TEXT NOT NULL,
  form medicine_form NOT NULL DEFAULT 'other',
  current_stock INTEGER NOT NULL DEFAULT 0 CHECK (current_stock >= 0),
  low_stock_threshold INTEGER NOT NULL DEFAULT 5 CHECK (low_stock_threshold >= 0),
  price_per_unit NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (price_per_unit >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (clinic_id, name)
);

CREATE TABLE stock_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
  created_by UUID REFERENCES users(id),
  movement_type stock_movement_type NOT NULL,
  quantity_delta INTEGER NOT NULL CHECK (quantity_delta <> 0),
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX stock_movements_medicine_created_idx ON stock_movements (medicine_id, created_at DESC);

CREATE TABLE prescriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id),
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  created_by UUID REFERENCES users(id),
  status prescription_status NOT NULL DEFAULT 'draft',
  diagnosis_notes TEXT,
  duration TEXT,
  general_instructions TEXT,
  footer_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  finalized_at TIMESTAMPTZ
);
CREATE INDEX prescriptions_patient_created_idx ON prescriptions (patient_id, created_at DESC);

CREATE TABLE prescription_diseases (
  prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
  disease_id UUID NOT NULL REFERENCES diseases(id),
  PRIMARY KEY (prescription_id, disease_id)
);

CREATE TABLE prescription_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
  medicine_id UUID REFERENCES medicines(id) ON DELETE SET NULL,
  medicine_name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  instructions TEXT,
  unit_price NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (unit_price >= 0),
  sort_order SMALLINT NOT NULL DEFAULT 0
);

CREATE TABLE footer_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id),
  note TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX footer_notes_clinic_order_idx ON footer_notes (clinic_id, sort_order);
