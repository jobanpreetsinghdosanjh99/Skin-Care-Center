from fastapi import APIRouter, HTTPException, Query

from app.clinics import get_or_create_default_clinic, next_patient_number
from app.db import get_connection
from app.schemas.patients import Patient, PatientCreate, PatientUpdate

router = APIRouter(prefix="/patients", tags=["patients"])


@router.get("", response_model=list[Patient])
def list_patients(
    search: str | None = Query(default=None),
    search_by: str = Query(default="name", pattern="^(name|phone|patient_number)$"),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> list[Patient]:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)

        column = {"name": "full_name", "phone": "phone", "patient_number": "patient_number"}[search_by]
        query = f"""
            SELECT * FROM patients
            WHERE clinic_id = %s
            {f"AND {column} ILIKE %s" if search else ""}
            ORDER BY created_at DESC
            LIMIT %s OFFSET %s
        """
        params: list = [clinic_id]
        if search:
            params.append(f"%{search}%")
        params.extend([limit, offset])

        rows = conn.execute(query, params).fetchall()
        return [Patient(**row) for row in rows]


@router.post("", response_model=Patient, status_code=201)
def create_patient(payload: PatientCreate) -> Patient:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        patient_number = next_patient_number(conn, clinic_id)

        row = conn.execute(
            """
            INSERT INTO patients (
                clinic_id, patient_number, full_name, age_years, age_months,
                date_of_birth, gender, phone, address, allergies, medical_history
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING *
            """,
            (
                clinic_id,
                patient_number,
                payload.full_name,
                payload.age_years,
                payload.age_months,
                payload.date_of_birth,
                payload.gender.value,
                payload.phone,
                payload.address,
                payload.allergies,
                payload.medical_history,
            ),
        ).fetchone()
        return Patient(**row)


@router.get("/{patient_id}", response_model=Patient)
def get_patient(patient_id: str) -> Patient:
    with get_connection() as conn:
        row = conn.execute("SELECT * FROM patients WHERE id = %s", (patient_id,)).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Patient not found")
        return Patient(**row)


@router.put("/{patient_id}", response_model=Patient)
def update_patient(patient_id: str, payload: PatientUpdate) -> Patient:
    with get_connection() as conn:
        row = conn.execute(
            """
            UPDATE patients SET
                full_name = %s, age_years = %s, age_months = %s, date_of_birth = %s,
                gender = %s, phone = %s, address = %s, allergies = %s,
                medical_history = %s, updated_at = now()
            WHERE id = %s
            RETURNING *
            """,
            (
                payload.full_name,
                payload.age_years,
                payload.age_months,
                payload.date_of_birth,
                payload.gender.value,
                payload.phone,
                payload.address,
                payload.allergies,
                payload.medical_history,
                patient_id,
            ),
        ).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Patient not found")
        return Patient(**row)


@router.delete("/{patient_id}", status_code=204)
def delete_patient(patient_id: str) -> None:
    with get_connection() as conn:
        result = conn.execute("DELETE FROM patients WHERE id = %s", (patient_id,))
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Patient not found")
