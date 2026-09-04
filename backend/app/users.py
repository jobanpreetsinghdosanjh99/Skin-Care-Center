import hashlib
import uuid

import psycopg


def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode("utf-8")).hexdigest()


def get_or_create_default_user(conn: psycopg.Connection, clinic_id: uuid.UUID) -> dict:
    """Single-clinic MVP: returns (creating if needed) the clinic's doctor
    account, seeded with default credentials (doctor@clinic.local /
    changeme123) so a fresh install can always log in without manual setup.
    """
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
        (clinic_id, hash_password("changeme123")),
    ).fetchone()
    return row
