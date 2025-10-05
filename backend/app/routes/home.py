from fastapi import APIRouter, HTTPException
from app.db import get_db_connection
from app.ml_utils import ref_df, get_week_row, anomaly_detection

router = APIRouter()

@router.get("/{user_id}")
def homepage(user_id: int):
    conn = get_db_connection()
    user = conn.execute("SELECT * FROM users WHERE id=?", (user_id,)).fetchone()
    conn.close()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    u = dict(user)
    week = u.get("gestationalWeek", 1)
    weight, height, hr = u.get("weight", 0), u.get("height", 0), u.get("heartRate", 0)

    week_row = get_week_row(ref_df, week)

    # Anomali
    rule_anomalies = []
    weight_status, height_status, hr_status = "normal", "normal", "normal"
    if week_row is not None:
        if "weight_min" in week_row and "weight_max" in week_row:
            if not (week_row["weight_min"] <= weight <= week_row["weight_max"]):
                rule_anomalies.append(f"Berat ({weight}) di luar [{week_row['weight_min']}-{week_row['weight_max']}]")
                weight_status = "abnormal"
        if "height_min" in week_row and "height_max" in week_row:
            if not (week_row["height_min"] <= height <= week_row["height_max"]):
                rule_anomalies.append(f"Panjang ({height}) di luar [{week_row['height_min']}-{week_row['height_max']}]")
                height_status = "abnormal"
        if "heart_rate_min" in week_row and "heart_rate_max" in week_row:
            if not (week_row["heart_rate_min"] <= hr <= week_row["heart_rate_max"]):
                rule_anomalies.append(f"HR ({hr}) di luar [{week_row['heart_rate_min']}-{week_row['heart_rate_max']}]")
                hr_status = "abnormal"

    iso_pred, iso_score = anomaly_detection(week, weight, height, hr)

    # Rekomendasi & artikel
    recommendations, articles = [], []
    if week_row is not None:
        if "recommendation" in week_row and week_row["recommendation"]:
            recommendations = [r.strip() for r in str(week_row["recommendation"]).split(",")]
        if "articles" in week_row and week_row["articles"]:
            urls = str(week_row["articles"]).split(";")
            articles = [{"title": f"Artikel Minggu {week}", "url": u.strip()} for u in urls]

    # Grafik perkembangan janin
    growth_chart = []
    for _, row in ref_df.iterrows():
        growth_chart.append({
            "week": int(row["week"]),
            "weight_max": row.get("weight_max", None),
            "height_max": row.get("height_max", None),
        })

    return {
        "profile": {
            "name": u["name"],
            "gestationalWeek": week,
            "weight": weight,
            "height": height,
            "bloodPressure": u.get("bloodPressure", ""),
            "heartRate": hr,
            "weight_status": weight_status,
            "height_status": height_status,
            "heartRate_status": hr_status,
        },
        "rule_anomalies": rule_anomalies,
        "anomaly_detection": {
            "score": iso_score,
            "is_anomaly": (iso_pred == -1) if iso_pred is not None else None,
        },
        "recommendations": recommendations,
        "articles": articles,
        "growth_chart": growth_chart,
        "patient_point": {
            "week": week,
            "weight": weight,
            "height": height,
        }
    }
