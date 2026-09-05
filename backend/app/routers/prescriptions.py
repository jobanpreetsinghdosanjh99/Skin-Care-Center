from fastapi import APIRouter, HTTPException

from app.clinics import get_or_create_default_clinic
from app.db import get_connection
from app.schemas.prescriptions import (
    Prescription,
    PrescriptionCreate,
    PrescriptionDiseaseInfo,
    PrescriptionItem,
)

router = APIRouter(prefix="/prescriptions", tags=["prescriptions"])


def _load_prescription(conn, prescription_id: str) -> dict | None:
    row = conn.execute(
        """
        SELECT p.*, pt.full_name AS patient_name, pt.patient_number AS patient_number
        FROM prescriptions p
        JOIN patients pt ON pt.id = p.patient_id
        WHERE p.id = %s
        """,
        (prescription_id,),
    ).fetchone()
    if not row:
        return None
    items = conn.execute(
        """
        SELECT * FROM prescription_items
        WHERE prescription_id = %s
        ORDER BY sort_order
        """,
        (prescription_id,),
    ).fetchall()
    diseases = conn.execute(
        """
        SELECT d.id, d.short_name, d.full_name
        FROM prescription_diseases pd
        JOIN diseases d ON d.id = pd.disease_id
        WHERE pd.prescription_id = %s
        ORDER BY d.short_name
        """,
        (prescription_id,),
    ).fetchall()
    return {
        **row,
        "items": [PrescriptionItem(**item) for item in items],
        "diseases": [PrescriptionDiseaseInfo(**disease) for disease in diseases],
    }


@router.get("", response_model=list[Prescription])
def list_prescriptions(patient_id: str | None = None) -> list[Prescription]:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)
        query = "SELECT id FROM prescriptions WHERE clinic_id = %s"
        params: list = [clinic_id]
        if patient_id:
            query += " AND patient_id = %s"
            params.append(patient_id)
        query += " ORDER BY created_at DESC"
        ids = [row["id"] for row in conn.execute(query, params).fetchall()]
        return [Prescription(**_load_prescription(conn, str(pid))) for pid in ids]


@router.post("", response_model=Prescription, status_code=201)
def create_prescription(payload: PrescriptionCreate) -> Prescription:
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)

        patient = conn.execute(
            "SELECT id FROM patients WHERE id = %s AND clinic_id = %s",
            (str(payload.patient_id), clinic_id),
        ).fetchone()
        if not patient:
            raise HTTPException(status_code=404, detail="Patient not found")

        footer_notes = conn.execute(
            """
            SELECT note FROM footer_notes
            WHERE clinic_id = %s AND is_active = true
            ORDER BY sort_order, created_at
            """,
            (clinic_id,),
        ).fetchall()
        combined_footer_note = (
            "\n".join(row["note"] for row in footer_notes) if footer_notes else None
        )

        prescription = conn.execute(
            """
            INSERT INTO prescriptions (
                clinic_id, patient_id, status, duration, diagnosis_notes,
                general_instructions, footer_note, finalized_at
            ) VALUES (%s, %s, 'finalized', %s, %s, %s, %s, now())
            RETURNING *
            """,
            (
                clinic_id,
                str(payload.patient_id),
                payload.duration,
                payload.diagnosis_notes,
                payload.general_instructions,
                combined_footer_note,
            ),
        ).fetchone()

        for disease_id in payload.disease_ids:
            conn.execute(
                """
                INSERT INTO prescription_diseases (prescription_id, disease_id)
                VALUES (%s, %s)
                """,
                (prescription["id"], str(disease_id)),
            )

        for index, item in enumerate(payload.items):
            conn.execute(
                """
                INSERT INTO prescription_items (
                    prescription_id, medicine_id, medicine_name, dosage,
                    quantity, instructions, sort_order
                ) VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    prescription["id"],
                    str(item.medicine_id) if item.medicine_id else None,
                    item.medicine_name,
                    item.dosage,
                    item.quantity,
                    item.instructions,
                    index,
                ),
            )
            if item.medicine_id:
                medicine = conn.execute(
                    "SELECT current_stock FROM medicines WHERE id = %s",
                    (str(item.medicine_id),),
                ).fetchone()
                if medicine and medicine["current_stock"] >= item.quantity:
                    conn.execute(
                        """
                        INSERT INTO stock_movements (medicine_id, movement_type, quantity_delta, note)
                        VALUES (%s, 'prescription', %s, %s)
                        """,
                        (str(item.medicine_id), -item.quantity, f"Prescription {prescription['id']}"),
                    )
                    conn.execute(
                        """
                        UPDATE medicines SET current_stock = current_stock - %s, updated_at = now()
                        WHERE id = %s
                        """,
                        (item.quantity, str(item.medicine_id)),
                    )

        return Prescription(**_load_prescription(conn, str(prescription["id"])))


@router.get("/{prescription_id}", response_model=Prescription)
def get_prescription(prescription_id: str) -> Prescription:
    with get_connection() as conn:
        data = _load_prescription(conn, prescription_id)
        if not data:
            raise HTTPException(status_code=404, detail="Prescription not found")
        return Prescription(**data)
