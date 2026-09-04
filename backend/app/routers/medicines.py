from fastapi import APIRouter, HTTPException, Query

from app.clinics import get_or_create_default_clinic
from app.db import get_connection
from app.schemas.medicines import (
    Medicine,
    MedicineCreate,
    MedicineUpdate,
    StockAdjustment,
    StockMovement,
)

router = APIRouter(prefix="/medicines", tags=["medicines"])


@router.get("", response_model=list[Medicine])
def list_medicines(
    search: str | None = Query(default=None),
    limit: int = Query(default=100, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
) -> list[Medicine]:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        query = """
            SELECT * FROM medicines
            WHERE clinic_id = %s
            {filter}
            ORDER BY name
            LIMIT %s OFFSET %s
        """.format(filter="AND name ILIKE %s" if search else "")
        params: list = [clinic_id]
        if search:
            params.append(f"%{search}%")
        params.extend([limit, offset])
        rows = conn.execute(query, params).fetchall()
        return [Medicine(**row) for row in rows]


@router.post("", response_model=Medicine, status_code=201)
def create_medicine(payload: MedicineCreate) -> Medicine:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        row = conn.execute(
            """
            INSERT INTO medicines (clinic_id, name, form, current_stock)
            VALUES (%s, %s, %s, %s)
            RETURNING *
            """,
            (clinic_id, payload.name, payload.form.value, payload.current_stock),
        ).fetchone()

        if payload.current_stock > 0:
            conn.execute(
                """
                INSERT INTO stock_movements (medicine_id, movement_type, quantity_delta, note)
                VALUES (%s, 'opening_balance', %s, 'Initial stock')
                """,
                (row["id"], payload.current_stock),
            )
        return Medicine(**row)


@router.put("/{medicine_id}", response_model=Medicine)
def update_medicine(medicine_id: str, payload: MedicineUpdate) -> Medicine:
    with get_connection() as conn:
        row = conn.execute(
            """
            UPDATE medicines SET name = %s, form = %s, updated_at = now()
            WHERE id = %s
            RETURNING *
            """,
            (payload.name, payload.form.value, medicine_id),
        ).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Medicine not found")
        return Medicine(**row)


@router.delete("/{medicine_id}", status_code=204)
def delete_medicine(medicine_id: str) -> None:
    with get_connection() as conn:
        result = conn.execute("DELETE FROM medicines WHERE id = %s", (medicine_id,))
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Medicine not found")


@router.post("/{medicine_id}/stock-adjustments", response_model=Medicine)
def adjust_stock(medicine_id: str, payload: StockAdjustment) -> Medicine:
    with get_connection() as conn:
        medicine = conn.execute(
            "SELECT * FROM medicines WHERE id = %s", (medicine_id,)
        ).fetchone()
        if not medicine:
            raise HTTPException(status_code=404, detail="Medicine not found")

        new_stock = medicine["current_stock"] + payload.quantity_delta
        if new_stock < 0:
            raise HTTPException(status_code=400, detail="Stock cannot go below zero")

        conn.execute(
            """
            INSERT INTO stock_movements (medicine_id, movement_type, quantity_delta, note)
            VALUES (%s, 'adjustment', %s, %s)
            """,
            (medicine_id, payload.quantity_delta, payload.note),
        )
        row = conn.execute(
            """
            UPDATE medicines SET current_stock = %s, updated_at = now()
            WHERE id = %s
            RETURNING *
            """,
            (new_stock, medicine_id),
        ).fetchone()
        return Medicine(**row)


@router.get("/{medicine_id}/stock-movements", response_model=list[StockMovement])
def get_stock_history(medicine_id: str) -> list[StockMovement]:
    with get_connection() as conn:
        rows = conn.execute(
            """
            SELECT * FROM stock_movements
            WHERE medicine_id = %s
            ORDER BY created_at DESC
            """,
            (medicine_id,),
        ).fetchall()
        return [StockMovement(**row) for row in rows]
