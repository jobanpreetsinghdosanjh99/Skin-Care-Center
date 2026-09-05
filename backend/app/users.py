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


# Additional staff accounts seeded alongside the default doctor account so
# the clinic can log in as either an unrestricted admin or a restricted
# manager (Patients + Medicines + view-only Prescriptions) without any
# manual account-creation step.
_SEED_STAFF_ACCOUNTS = [
    ("Admin", "admin@clinic.local", "admin123", "admin"),
    ("Manager", "manager@clinic.local", "manager123", "manager"),
]


def ensure_seed_staff_accounts(conn: psycopg.Connection, clinic_id: uuid.UUID) -> None:
    for full_name, email, password, role in _SEED_STAFF_ACCOUNTS:
        exists = conn.execute(
            "SELECT 1 FROM users WHERE lower(email) = lower(%s)", (email,)
        ).fetchone()
        if exists:
            continue
        conn.execute(
            """
            INSERT INTO users (clinic_id, full_name, email, password_hash, role)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (clinic_id, full_name, email, hash_password(password), role),
        )
