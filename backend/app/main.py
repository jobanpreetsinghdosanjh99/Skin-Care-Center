from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.auth import get_current_user_id
from app.routers import auth, clinics, diseases, medicines, patients, prescriptions, settings


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

app.include_router(auth.router)
app.include_router(clinics.router, dependencies=_auth_required)
app.include_router(patients.router, dependencies=_auth_required)
app.include_router(medicines.router, dependencies=_auth_required)
app.include_router(diseases.router, dependencies=_auth_required)
app.include_router(prescriptions.router, dependencies=_auth_required)
app.include_router(settings.router, dependencies=_auth_required)


@app.get("/health", tags=["system"])
def health_check() -> dict[str, str]:
    return {"status": "ok"}
