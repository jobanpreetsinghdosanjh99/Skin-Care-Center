import uuid

import psycopg


def get_or_create_default_clinic(conn: psycopg.Connection) -> uuid.UUID:
    """Return the active clinic id, creating a default clinic on first run.

    The current MVP is single-clinic; multi-clinic selection can be layered
    on top of this once the clinic-switching UI is built.
    """
    row = conn.execute("SELECT id FROM clinics ORDER BY created_at LIMIT 1").fetchone()
    if row:
        return row["id"]

    row = conn.execute(
        "INSERT INTO clinics (name) VALUES (%s) RETURNING id",
        ("Skin Care Centre",),
    ).fetchone()
    return row["id"]


def next_patient_number(conn: psycopg.Connection, clinic_id: uuid.UUID) -> str:
    row = conn.execute(
        """
        SELECT patient_number FROM patients
        WHERE clinic_id = %s
        ORDER BY created_at DESC
        LIMIT 1
        """,
        (clinic_id,),
    ).fetchone()

    if not row:
        return "P-00001"

    last_sequence = int(row["patient_number"].split("-")[-1])
    return f"P-{last_sequence + 1:05d}"
