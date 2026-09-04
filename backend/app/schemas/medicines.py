import uuid
from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class MedicineForm(str, Enum):
    cream = "cream"
    soap = "soap"
    tablet = "tablet"
    capsule = "capsule"
    lotion = "lotion"
    sunscreen = "sunscreen"
    face_wash = "face_wash"
    serum = "serum"
    shampoo = "shampoo"
    syrup = "syrup"
    injection = "injection"
    other = "other"


class MedicineBase(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    form: MedicineForm = MedicineForm.other


class MedicineCreate(MedicineBase):
    current_stock: int = Field(default=0, ge=0)


class MedicineUpdate(MedicineBase):
    pass


class Medicine(MedicineBase):
    id: uuid.UUID
    clinic_id: uuid.UUID
    current_stock: int
    low_stock_threshold: int
    created_at: datetime
    updated_at: datetime


class StockMovementType(str, Enum):
    opening_balance = "opening_balance"
    adjustment = "adjustment"
    prescription = "prescription"
    purchase = "purchase"
    return_stock = "return"
    correction = "correction"


class StockAdjustment(BaseModel):
    quantity_delta: int = Field(description="Positive to add stock, negative to remove")
    note: str | None = None


class StockMovement(BaseModel):
    id: uuid.UUID
    medicine_id: uuid.UUID
    movement_type: StockMovementType
    quantity_delta: int
    note: str | None
    created_at: datetime
