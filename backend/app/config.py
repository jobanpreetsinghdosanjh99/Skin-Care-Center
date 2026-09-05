import os

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=os.environ.get("ENV_FILE", "env/.env.development"),
        extra="ignore",
    )

    database_url: str = "postgresql://postgres:postgres@localhost:5432/skin_care_centre"
    jwt_secret: str = "change-me-in-production"
    default_clinic_id: str | None = None
    frontend_origin_regex: str = r"http://(localhost|127\.0\.0\.1)(:\d+)?"


settings = Settings()
