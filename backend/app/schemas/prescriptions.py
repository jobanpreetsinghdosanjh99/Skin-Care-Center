import uuid
from datetime import datetime
from decimal import Decimal
from enum import Enum

from pydantic import BaseModel, Field


class PrescriptionStatus(str, Enum):
    draft = "draft"
    finalized = "finalized"
    cancelled = "cancelled"


class PrescriptionItemCreate(BaseModel):
    medicine_id: uuid.UUID | None = None
    medicine_name: str
    dosage: str
    quantity: int = Field(gt=0)
    instructions: str | None = None
    unit_price: Decimal = Field(default=Decimal("0"), ge=0)


class PrescriptionItem(PrescriptionItemCreate):
    id: uuid.UUID
    prescription_id: uuid.UUID
    sort_order: int


class PrescriptionDiseaseInfo(BaseModel):
    id: uuid.UUID
    short_name: str
    full_name: str


class PrescriptionCreate(BaseModel):
    patient_id: uuid.UUID
    duration: str | None = None
    diagnosis_notes: str | None = None
    general_instructions: str | None = None
    disease_ids: list[uuid.UUID] = Field(default_factory=list)
    items: list[PrescriptionItemCreate] = Field(default_factory=list, min_length=1)


class Prescription(BaseModel):
    id: uuid.UUID
    clinic_id: uuid.UUID
    patient_id: uuid.UUID
    patient_name: str
    patient_number: str
    status: PrescriptionStatus
    duration: str | None
    diagnosis_notes: str | None
    general_instructions: str | None
    footer_note: str | None
    created_at: datetime
    finalized_at: datetime | None
    items: list[PrescriptionItem] = Field(default_factory=list)
    diseases: list[PrescriptionDiseaseInfo] = Field(default_factory=list)
    total_amount: Decimal = Decimal("0")
