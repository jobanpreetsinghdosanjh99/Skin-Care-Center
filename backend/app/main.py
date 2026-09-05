from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.auth import get_current_user_id, require_roles
from app.routers import (
    auth,
    clinics,
    diseases,
    medicines,
    patients,
    prescriptions,
    reports,
    settings,
)


@asynccontextmanager
async def lifespan(_: FastAPI):
    yield


app = FastAPI(
    title="Skin Care Centre API",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    # Flutter's debug web server picks a random localhost port on every
    # `flutter run`, so match any localhost/127.0.0.1 origin instead of a
    # fixed allow-list.
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Every data router requires a valid login session (bearer token) except
# /auth/login itself and /health — this is what actually enforces the
# login screen instead of leaving the API fully open to anyone who knows
# the URL.
_auth_required = [Depends(get_current_user_id)]

# Managing the disease reference list is an admin/doctor-only activity —
# the 'manager' role only needs Patients, Medicines, and view-only
# Prescriptions (see per-route restrictions in those routers).
_admin_only = [Depends(require_roles("admin", "doctor"))]

app.include_router(auth.router)
app.include_router(clinics.router, dependencies=_auth_required)
app.include_router(patients.router, dependencies=_auth_required)
app.include_router(medicines.router, dependencies=_auth_required)
app.include_router(diseases.router, dependencies=_admin_only)
app.include_router(prescriptions.router, dependencies=_auth_required)
app.include_router(settings.router, dependencies=_auth_required)
# Sales/revenue reporting is an owner-level view — 'manager' accounts can see
# an individual prescription's amount but not clinic-wide takings.
app.include_router(reports.router, dependencies=_admin_only)


@app.get("/health", tags=["system"])
def health_check() -> dict[str, str]:
    return {"status": "ok"}
