from fastapi import APIRouter, HTTPException, Query

from app.clinics import get_or_create_default_clinic
from app.db import get_connection
from app.schemas.diseases import Disease, DiseaseCreate, DiseaseUpdate

router = APIRouter(prefix="/diseases", tags=["diseases"])


@router.get("", response_model=list[Disease])
def list_diseases(
    short_name: str | None = Query(default=None),
    full_name: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=10, ge=1, le=200),
) -> list[Disease]:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        filters = []
        params: list = [clinic_id]
        if short_name:
            filters.append("short_name ILIKE %s")
            params.append(f"%{short_name}%")
        if full_name:
            filters.append("full_name ILIKE %s")
            params.append(f"%{full_name}%")
        filter_sql = f"AND {' AND '.join(filters)}" if filters else ""

        params.extend([page_size, (page - 1) * page_size])
        rows = conn.execute(
            f"""
            SELECT * FROM diseases
            WHERE clinic_id = %s
            {filter_sql}
            ORDER BY short_name
            LIMIT %s OFFSET %s
            """,
            params,
        ).fetchall()
        return [Disease(**row) for row in rows]


@router.post("", response_model=Disease, status_code=201)
def create_disease(payload: DiseaseCreate) -> Disease:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        row = conn.execute(
            """
            INSERT INTO diseases (clinic_id, short_name, full_name, description)
            VALUES (%s, %s, %s, %s)
            RETURNING *
            """,
            (clinic_id, payload.short_name, payload.full_name, payload.description),
        ).fetchone()
        return Disease(**row)


@router.put("/{disease_id}", response_model=Disease)
def update_disease(disease_id: str, payload: DiseaseUpdate) -> Disease:
    with get_connection() as conn:
        row = conn.execute(
            """
            UPDATE diseases SET short_name = %s, full_name = %s, description = %s, updated_at = now()
            WHERE id = %s
            RETURNING *
            """,
            (payload.short_name, payload.full_name, payload.description, disease_id),
        ).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Disease not found")
        return Disease(**row)


@router.delete("/{disease_id}", status_code=204)
def delete_disease(disease_id: str) -> None:
    with get_connection() as conn:
        result = conn.execute("DELETE FROM diseases WHERE id = %s", (disease_id,))
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Disease not found")
