from fastapi import APIRouter, HTTPException

from app.db import get_connection
from app.schemas.clinics import Clinic, ClinicCreate

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
