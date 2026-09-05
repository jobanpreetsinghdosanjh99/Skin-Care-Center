import uuid
from datetime import date, datetime
from enum import Enum

from pydantic import BaseModel, Field


class Gender(str, Enum):
    male = "male"
    female = "female"
    other = "other"
    prefer_not_to_say = "prefer_not_to_say"


class PatientBase(BaseModel):
    full_name: str = Field(min_length=1, max_length=200)
    age_years: int | None = Field(default=None, ge=0, le=150)
    age_months: int | None = Field(default=None, ge=0, le=11)
    date_of_birth: date | None = None
    gender: Gender = Gender.prefer_not_to_say
    phone: str = Field(min_length=5, max_length=20)
    address: str | None = None
    allergies: str | None = None
    medical_history: str | None = None


class PatientCreate(PatientBase):
    pass


class PatientUpdate(PatientBase):
    pass


class Patient(PatientBase):
    id: uuid.UUID
    clinic_id: uuid.UUID
    patient_number: str
    created_at: datetime
    updated_at: datetime
