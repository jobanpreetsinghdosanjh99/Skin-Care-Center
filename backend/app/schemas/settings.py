from pydantic import BaseModel, Field


class ClinicSettings(BaseModel):
    name: str
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    prescription_footer_note: str | None = None


class ClinicSettingsUpdate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    phone: str | None = None
    email: str | None = None
    address: str | None = None


class FooterNoteCreate(BaseModel):
    note: str = Field(min_length=1)


class PasswordChange(BaseModel):
    current_password: str
    new_password: str = Field(min_length=8)
