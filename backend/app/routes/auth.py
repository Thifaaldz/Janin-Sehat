from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
from app.db import get_db_connection
import sqlite3

router = APIRouter()

# 📌 Registrasi user baru
@router.post("/register")
def register(user: dict):
    try:
        conn = get_db_connection()
        cursor = conn.execute(
            """
            INSERT INTO users (
                name, email, password, gestationalWeek,
                weight, height, bloodPressure, heartRate,
                hptp, dueDate
            ) VALUES (?,?,?,?,?,?,?,?,?,?)
            """,
            (
                user["name"],
                user["email"],
                user["password"],
                user.get("gestationalWeek", 1),
                user.get("weight", 0),
                user.get("height", 0),
                user.get("bloodPressure", ""),
                user.get("heartRate", 0),
                user.get("hptp", ""),     # ✅ simpan HPHT
                user.get("dueDate", "")   # ✅ opsional
            )
        )
        conn.commit()
        user_id = cursor.lastrowid
        conn.close()
        return JSONResponse(content={"message": "Register berhasil", "user_id": user_id})
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Email sudah terdaftar")


# 📌 Login
@router.post("/login")
def login(user: dict):
    conn = get_db_connection()
    row = conn.execute(
        "SELECT * FROM users WHERE email=? AND password=?",
        (user["email"], user["password"])
    ).fetchone()
    conn.close()
    if row:
        return dict(row)
    raise HTTPException(status_code=401, detail="Email atau password salah")


# 📌 Ambil profile user (termasuk HPHT & dueDate)
@router.get("/profile/{user_id}")
def get_profile(user_id: int):
    conn = get_db_connection()
    row = conn.execute("SELECT * FROM users WHERE id=?", (user_id,)).fetchone()
    conn.close()
    if row:
        return dict(row)   # ✅ otomatis return semua kolom, termasuk hptp
    raise HTTPException(status_code=404, detail="User tidak ditemukan")
