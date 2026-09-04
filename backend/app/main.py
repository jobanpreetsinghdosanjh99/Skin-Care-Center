from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import diseases, medicines, patients, prescriptions, settings


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

app.include_router(patients.router)
app.include_router(medicines.router)
app.include_router(diseases.router)
app.include_router(prescriptions.router)
app.include_router(settings.router)


@app.get("/health", tags=["system"])
def health_check() -> dict[str, str]:
    return {"status": "ok"}
