import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class DiseaseBase(BaseModel):
    short_name: str = Field(min_length=1, max_length=50)
    full_name: str = Field(min_length=1, max_length=200)
    description: str | None = None


class DiseaseCreate(DiseaseBase):
    pass


class DiseaseUpdate(DiseaseBase):
    pass


class Disease(DiseaseBase):
    id: uuid.UUID
    clinic_id: uuid.UUID
    created_at: datetime
    updated_at: datetime
