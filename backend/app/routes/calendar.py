# /root/janinsehat/backend/app/routes/calendar.py

from fastapi import APIRouter
from datetime import datetime, timedelta

router = APIRouter()

@router.get("/schedule")
def get_calendar_schedule(hpht: str):
    """
    Generate jadwal kehamilan berdasarkan HPHT (YYYY-MM-DD).
    """
    try:
        hpht_date = datetime.strptime(hpht, "%Y-%m-%d")
    except ValueError:
        return {"error": "Format tanggal harus YYYY-MM-DD"}

    # Perkiraan due date (280 hari setelah HPHT)
    edd_date = hpht_date + timedelta(days=280)

    schedule = []
    current_date = hpht_date
    bulan = 1

    # Tambahkan check-up bulanan
    while current_date < edd_date:
        schedule.append({
            "tanggal": current_date.strftime("%Y-%m-%d"),
            "kegiatan": f"Check-up Bulan ke-{bulan}"
        })
        current_date += timedelta(days=30)
        bulan += 1

    # Tambahkan USG Trimester 1 & 3
    usg_t1 = hpht_date + timedelta(weeks=12)
    if usg_t1 < edd_date:
        schedule.append({
            "tanggal": usg_t1.strftime("%Y-%m-%d"),
            "kegiatan": "USG Trimester 1"
        })

    usg_t3 = hpht_date + timedelta(weeks=30)
    if usg_t3 < edd_date:
        schedule.append({
            "tanggal": usg_t3.strftime("%Y-%m-%d"),
            "kegiatan": "USG Trimester 3"
        })

    # Urutkan berdasarkan tanggal
    schedule.sort(key=lambda x: x["tanggal"])

    return {
        "hpht": hpht_date.strftime("%Y-%m-%d"),
        "edd": edd_date.strftime("%Y-%m-%d"),
        "schedule": schedule
    }
