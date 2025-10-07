
from fastapi import APIRouter, HTTPException, Body
from fastapi.responses import JSONResponse
from app.db import get_db_connection

router = APIRouter()

# ==========================
# 📌 Ambil profil + riwayat
# ==========================
@router.get("/{user_id}")
def get_profile(user_id: int):
    conn = get_db_connection()
    user = conn.execute("SELECT * FROM users WHERE id=?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    growth = conn.execute(
        "SELECT * FROM fetal_growth WHERE user_id=? ORDER BY created_at DESC", (user_id,)
    ).fetchall()
    conn.close()

    return {
        "user": dict(user),
        "fetal_growth": [dict(row) for row in growth],
    }

# ================================================
# 📌 Tambah riwayat perkembangan janin + update user
# ================================================
@router.post("/{user_id}/growth")
def update_growth(user_id: int, data: dict):
    conn = get_db_connection()
    old = conn.execute("SELECT * FROM users WHERE id=?", (user_id,)).fetchone()
    if not old:
        conn.close()
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    # Simpan data lama ke fetal_growth
    conn.execute(
        """
        INSERT INTO fetal_growth (user_id, week, fetal_weight, fetal_length, notes)
        VALUES (?, ?, ?, ?, ?)
        """,
        (
            user_id,
            old["gestationalWeek"],
            old["weight"],
            old["height"],
            f"Data sebelumnya: tekanan darah {old['bloodPressure']}, detak jantung {old['heartRate']}",
        ),
    )

    # Update data user sesuai input baru
    conn.execute(
        """
        UPDATE users SET
            gestationalWeek=?,
            weight=?,
            height=?,
            bloodPressure=?,
            heartRate=?
        WHERE id=?
        """,
        (
            data.get("week", old["gestationalWeek"]),
            data.get("fetalWeight", old["weight"]),
            data.get("fetalLength", old["height"]),
            data.get("bloodPressure", old["bloodPressure"]),
            data.get("heartRate", old["heartRate"]),
            user_id,
        ),
    )

    conn.commit()
    conn.close()
    return JSONResponse(content={"message": "✅ Data perkembangan janin diperbarui & disimpan ke riwayat"})

# =============================
# 📌 Update HPHT / due date
# =============================
@router.post("/{user_id}/update_hpht")
def update_hpht(user_id: int, data: dict):
    hpht = data.get("hptp")
    if not hpht:
        raise HTTPException(status_code=400, detail="HPHT harus diisi")

    conn = get_db_connection()
    row = conn.execute("SELECT * FROM users WHERE id=?", (user_id,)).fetchone()
    if not row:
        conn.close()
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    conn.execute("UPDATE users SET hptp=? WHERE id=?", (hpht, user_id))
    conn.commit()
    conn.close()
    return JSONResponse(content={"message": "✅ HPHT berhasil diperbarui", "hptp": hpht})

# ==================================
# 📌 Update profil utama user (PUT)
# ==================================
@router.put("/update/{user_id}")
def update_profile(user_id: int, data: dict = Body(...)):
    conn = get_db_connection()
    user = conn.execute("SELECT * FROM users WHERE id=?", (user_id,)).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    conn.execute(
        """
        UPDATE users
        SET name=?, email=?, gestationalWeek=?, bloodPressure=?, heartRate=?
        WHERE id=?
        """,
        (
            data.get("name", user["name"]),
            data.get("email", user["email"]),
            data.get("gestationalWeek", user["gestationalWeek"]),
            data.get("bloodPressure", user["bloodPressure"]),
            data.get("heartRate", user["heartRate"]),
            user_id,
        ),
    )

    conn.commit()
    conn.close()

    return JSONResponse(content={"message": "✅ Profil berhasil diperbarui"})

