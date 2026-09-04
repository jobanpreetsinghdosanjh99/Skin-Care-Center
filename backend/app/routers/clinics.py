from fastapi import APIRouter, HTTPException

from app.db import get_connection
from app.schemas.clinics import Clinic, ClinicCreate, ClinicUpdate

router = APIRouter(prefix="/clinics", tags=["clinics"])


@router.get("/active", response_model=Clinic)
def get_active_clinic() -> Clinic:
    with get_connection() as conn:
        row = conn.execute(
            "SELECT * FROM clinics WHERE is_active = true ORDER BY created_at LIMIT 1"
        ).fetchone()
        if not row:
            row = conn.execute(
                "SELECT * FROM clinics ORDER BY created_at LIMIT 1"
            ).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="No clinic configured")
        return Clinic(**row)


@router.get("", response_model=list[Clinic])
def list_clinics() -> list[Clinic]:
    with get_connection() as conn:
        rows = conn.execute("SELECT * FROM clinics ORDER BY created_at").fetchall()
        return [Clinic(**row) for row in rows]


@router.post("", response_model=Clinic, status_code=201)
def create_clinic(payload: ClinicCreate) -> Clinic:
    with get_connection() as conn:
        row = conn.execute(
            """
            INSERT INTO clinics (name, phone, email, address, is_active)
            VALUES (%s, %s, %s, %s, false)
            RETURNING *
            """,
            (payload.name, payload.phone, payload.email, payload.address),
        ).fetchone()
        return Clinic(**row)


@router.post("/{clinic_id}/activate", response_model=Clinic)
def activate_clinic(clinic_id: str) -> Clinic:
    with get_connection() as conn:
        exists = conn.execute(
            "SELECT id FROM clinics WHERE id = %s", (clinic_id,)
        ).fetchone()
        if not exists:
            raise HTTPException(status_code=404, detail="Clinic not found")

        conn.execute("UPDATE clinics SET is_active = false")
        row = conn.execute(
            """
            UPDATE clinics SET is_active = true, updated_at = now()
            WHERE id = %s
            RETURNING *
            """,
            (clinic_id,),
        ).fetchone()
        return Clinic(**row)


@router.put("/{clinic_id}", response_model=Clinic)
def update_clinic(clinic_id: str, payload: ClinicUpdate) -> Clinic:
    with get_connection() as conn:
        row = conn.execute(
            """
            UPDATE clinics
            SET name = %s, phone = %s, email = %s, address = %s, updated_at = now()
            WHERE id = %s
            RETURNING *
            """,
            (payload.name, payload.phone, payload.email, payload.address, clinic_id),
        ).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Clinic not found")
        return Clinic(**row)


@router.delete("/{clinic_id}", status_code=204)
def delete_clinic(clinic_id: str) -> None:
    with get_connection() as conn:
        row = conn.execute(
            "SELECT is_active FROM clinics WHERE id = %s", (clinic_id,)
        ).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Clinic not found")

        total = conn.execute("SELECT count(*) AS c FROM clinics").fetchone()["c"]
        if total <= 1:
            raise HTTPException(
                status_code=400, detail="Cannot delete the only clinic"
            )

        has_patients = conn.execute(
            "SELECT 1 FROM patients WHERE clinic_id = %s LIMIT 1", (clinic_id,)
        ).fetchone()
        if has_patients:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Cannot delete a clinic with existing patients, "
                    "prescriptions, or other records. Deactivate it instead."
                ),
            )

        conn.execute("DELETE FROM footer_notes WHERE clinic_id = %s", (clinic_id,))
        conn.execute("DELETE FROM diseases WHERE clinic_id = %s", (clinic_id,))
        conn.execute(
            """
            DELETE FROM stock_movements
            WHERE medicine_id IN (SELECT id FROM medicines WHERE clinic_id = %s)
            """,
            (clinic_id,),
        )
        conn.execute("DELETE FROM medicines WHERE clinic_id = %s", (clinic_id,))
        conn.execute("DELETE FROM users WHERE clinic_id = %s", (clinic_id,))
        conn.execute("DELETE FROM clinics WHERE id = %s", (clinic_id,))

        if row["is_active"]:
            fallback = conn.execute(
                "SELECT id FROM clinics ORDER BY created_at LIMIT 1"
            ).fetchone()
            if fallback:
                conn.execute(
                    "UPDATE clinics SET is_active = true, updated_at = now() WHERE id = %s",
                    (fallback["id"],),
                )
