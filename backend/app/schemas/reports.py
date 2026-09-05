import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel


class SalesBucket(BaseModel):
    date: str
    total: Decimal
    prescription_count: int


class SalesReportPrescription(BaseModel):
    id: uuid.UUID
    created_at: datetime
    patient_name: str
    patient_number: str
    amount: Decimal
    item_count: int


class SalesReport(BaseModel):
    start: datetime
    end: datetime
    total: Decimal
    prescription_count: int
    daily: list[SalesBucket]
    prescriptions: list[SalesReportPrescription]
