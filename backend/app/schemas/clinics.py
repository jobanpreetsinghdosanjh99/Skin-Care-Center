import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class ClinicCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    phone: str | None = None
    email: str | None = None
    address: str | None = None


class ClinicUpdate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    phone: str | None = None
    email: str | None = None
    address: str | None = None


class Clinic(BaseModel):
    id: uuid.UUID
    name: str
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    prescription_footer_note: str | None = None
    is_active: bool
    created_at: datetime
    updated_at: datetime
