import uuid

from fastapi import APIRouter, HTTPException

from app.clinics import get_or_create_default_clinic
from app.db import get_connection
from app.schemas.settings import (
    ClinicSettings,
    ClinicSettingsUpdate,
    FooterNote,
    FooterNoteCreate,
    FooterNoteUpdate,
    PasswordChange,
)
from app.users import get_or_create_default_user, hash_password

router = APIRouter(prefix="/settings", tags=["settings"])


def _get_or_create_default_user(conn, clinic_id: uuid.UUID) -> dict:
    return get_or_create_default_user(conn, clinic_id)


def _hash_password(password: str) -> str:
    return hash_password(password)


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


@router.get("/footer-notes", response_model=list[FooterNote])
def list_footer_notes() -> list[FooterNote]:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        rows = conn.execute(
            "SELECT * FROM footer_notes WHERE clinic_id = %s ORDER BY sort_order, created_at",
            (clinic_id,),
        ).fetchall()
        return [FooterNote(**row) for row in rows]


@router.post("/footer-notes", response_model=FooterNote, status_code=201)
def add_footer_note(payload: FooterNoteCreate) -> FooterNote:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        row = conn.execute(
            """
            INSERT INTO footer_notes (clinic_id, note, sort_order)
            VALUES (%s, %s, %s)
            RETURNING *
            """,
            (clinic_id, payload.note, payload.sort_order),
        ).fetchone()
        return FooterNote(**row)


@router.put("/footer-notes/{note_id}", response_model=FooterNote)
def update_footer_note(note_id: str, payload: FooterNoteUpdate) -> FooterNote:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        row = conn.execute(
            """
            UPDATE footer_notes
            SET note = %s, sort_order = %s, is_active = %s, updated_at = now()
            WHERE id = %s AND clinic_id = %s
            RETURNING *
            """,
            (payload.note, payload.sort_order, payload.is_active, note_id, clinic_id),
        ).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Footer note not found")
        return FooterNote(**row)


@router.delete("/footer-notes/{note_id}", status_code=204)
def delete_footer_note(note_id: str) -> None:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        deleted = conn.execute(
            "DELETE FROM footer_notes WHERE id = %s AND clinic_id = %s RETURNING id",
            (note_id, clinic_id),
        ).fetchone()
        if not deleted:
            raise HTTPException(status_code=404, detail="Footer note not found")


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
