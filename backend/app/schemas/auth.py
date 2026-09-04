import uuid

from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    email: str = Field(min_length=1)
    password: str = Field(min_length=1)


class LoginResponse(BaseModel):
    access_token: str
    user_id: uuid.UUID
    full_name: str
    email: str
    role: str
    clinic_id: uuid.UUID
