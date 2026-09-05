from datetime import datetime
from decimal import Decimal

from fastapi import APIRouter, Query

from app.clinics import get_or_create_default_clinic
from app.db import get_connection
from app.schemas.reports import SalesBucket, SalesReport, SalesReportPrescription

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/sales", response_model=SalesReport)
def sales_report(
    start: datetime = Query(..., alias="from"),
    end: datetime = Query(..., alias="to"),
) -> SalesReport:
    """Total sale (revenue) for an arbitrary date/time window.

    `from` is inclusive and `to` is exclusive, so a single day is queried
    as from=2024-05-01T00:00:00 & to=2024-05-02T00:00:00, and a narrower
    time frame (e.g. a single morning) works with the same endpoint.
    """
    with get_connection() as conn:
        clinic_id = get_or_create_default_clinic(conn)

        rows = conn.execute(
            """
            SELECT
                p.id,
                p.created_at,
                pt.full_name AS patient_name,
                pt.patient_number AS patient_number,
                COALESCE(SUM(pi.quantity * pi.unit_price), 0) AS amount,
                COALESCE(SUM(pi.quantity), 0) AS item_count
            FROM prescriptions p
            JOIN patients pt ON pt.id = p.patient_id
            LEFT JOIN prescription_items pi ON pi.prescription_id = p.id
            WHERE p.clinic_id = %s
              AND p.created_at >= %s
              AND p.created_at < %s
            GROUP BY p.id, p.created_at, pt.full_name, pt.patient_number
            ORDER BY p.created_at DESC
            """,
            (clinic_id, start, end),
        ).fetchall()

        prescriptions = [
            SalesReportPrescription(
                id=row["id"],
                created_at=row["created_at"],
                patient_name=row["patient_name"],
                patient_number=row["patient_number"],
                amount=row["amount"],
                item_count=int(row["item_count"]),
            )
            for row in rows
        ]

        buckets: dict[str, dict] = {}
        for row in rows:
            key = row["created_at"].date().isoformat()
            bucket = buckets.setdefault(
                key, {"total": Decimal("0"), "count": 0}
            )
            bucket["total"] += Decimal(str(row["amount"]))
            bucket["count"] += 1

        daily = [
            SalesBucket(date=key, total=value["total"], prescription_count=value["count"])
            for key, value in sorted(buckets.items())
        ]

        total = sum((Decimal(str(row["amount"])) for row in rows), Decimal("0"))

        return SalesReport(
            start=start,
            end=end,
            total=total,
            prescription_count=len(rows),
            daily=daily,
            prescriptions=prescriptions,
        )
