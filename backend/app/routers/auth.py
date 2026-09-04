from fastapi import APIRouter, HTTPException

from app.auth import create_access_token
from app.clinics import get_or_create_default_clinic
from app.db import get_connection
from app.schemas.auth import LoginRequest, LoginResponse
from app.users import get_or_create_default_user, hash_password

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=LoginResponse)
def login(payload: LoginRequest) -> LoginResponse:
    with get_connection() as conn:
        # Single-clinic MVP: make sure the default clinic/user exist so a
        # fresh install can always log in with the seeded credentials
        # (doctor@clinic.local / changeme123) without any manual setup.
        clinic_id = get_or_create_default_clinic(conn)
        get_or_create_default_user(conn, clinic_id)

        user = conn.execute(
            "SELECT * FROM users WHERE lower(email) = lower(%s)",
            (payload.email,),
        ).fetchone()
        if not user or user["password_hash"] != hash_password(payload.password):
            raise HTTPException(status_code=401, detail="Invalid email or password")
        if not user["is_active"]:
            raise HTTPException(status_code=403, detail="This account is disabled")

        token = create_access_token(user["id"], user["clinic_id"])
        return LoginResponse(
            access_token=token,
            user_id=user["id"],
            full_name=user["full_name"],
            email=user["email"],
            role=user["role"],
            clinic_id=user["clinic_id"],
        )
