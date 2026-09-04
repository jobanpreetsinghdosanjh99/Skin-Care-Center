import hashlib
import uuid

from fastapi import APIRouter, HTTPException

from app.clinics import get_or_create_default_clinic
from app.db import get_connection
from app.schemas.settings import ClinicSettings, ClinicSettingsUpdate, FooterNoteCreate, PasswordChange

router = APIRouter(prefix="/settings", tags=["settings"])


def _hash_password(password: str) -> str:
    return hashlib.sha256(password.encode("utf-8")).hexdigest()


def _get_or_create_default_user(conn, clinic_id: uuid.UUID) -> dict:
    row = conn.execute(
        "SELECT * FROM users WHERE clinic_id = %s ORDER BY created_at LIMIT 1",
        (clinic_id,),
    ).fetchone()
    if row:
        return row

    row = conn.execute(
        """
        INSERT INTO users (clinic_id, full_name, email, password_hash, role)
        VALUES (%s, 'Doctor', 'doctor@clinic.local', %s, 'doctor')
        RETURNING *
        """,
        (clinic_id, _hash_password("changeme123")),
    ).fetchone()
    return row


@router.get("/me", response_model=dict)
def get_current_user() -> dict:
    """Single-user MVP: returns (creating if needed) the clinic's default user id."""
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        user = _get_or_create_default_user(conn, clinic_id)
        return {"id": str(user["id"]), "full_name": user["full_name"], "email": user["email"]}


@router.get("/clinic", response_model=ClinicSettings)
def get_clinic_settings() -> ClinicSettings:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        row = conn.execute("SELECT * FROM clinics WHERE id = %s", (clinic_id,)).fetchone()
        return ClinicSettings(**row)


@router.put("/clinic", response_model=ClinicSettings)
def update_clinic_settings(payload: ClinicSettingsUpdate) -> ClinicSettings:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        row = conn.execute(
            """
            UPDATE clinics SET name = %s, phone = %s, email = %s, address = %s, updated_at = now()
            WHERE id = %s
            RETURNING *
            """,
            (payload.name, payload.phone, payload.email, payload.address, clinic_id),
        ).fetchone()
        return ClinicSettings(**row)


@router.get("/footer-notes", response_model=list[str])
def list_footer_notes() -> list[str]:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        rows = conn.execute(
            "SELECT note FROM footer_notes WHERE clinic_id = %s ORDER BY created_at DESC",
            (clinic_id,),
        ).fetchall()
        return [row["note"] for row in rows]


@router.post("/footer-notes", status_code=201)
def add_footer_note(payload: FooterNoteCreate) -> dict[str, str]:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        conn.execute(
            "INSERT INTO footer_notes (clinic_id, note) VALUES (%s, %s)",
            (clinic_id, payload.note),
        )
        return {"note": payload.note}


@router.post("/password", status_code=204)
def change_password(payload: PasswordChange, user_id: str | None = None) -> None:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        user = (
            conn.execute("SELECT * FROM users WHERE id = %s", (user_id,)).fetchone()
            if user_id
            else _get_or_create_default_user(conn, clinic_id)
        )
        if not user or user["password_hash"] != _hash_password(payload.current_password):
            raise HTTPException(status_code=400, detail="Current password is incorrect")
        conn.execute(
            "UPDATE users SET password_hash = %s, updated_at = now() WHERE id = %s",
            (_hash_password(payload.new_password), user["id"]),
        )
