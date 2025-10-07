from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.db import init_db
from app.routes import auth, home, bidan, calendar, profile  # ✅ profile sudah disertakan

app = FastAPI(title="JaninSehat API")

# ✅ Konfigurasi CORS agar Flutter bisa akses
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ganti dengan domain spesifik jika perlu
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Inisialisasi database
init_db()

# ✅ Daftarkan semua router
app.include_router(auth.router, prefix="/auth", tags=["Auth"])
app.include_router(home.router, prefix="/home", tags=["Home"])
app.include_router(bidan.router, prefix="/bidan", tags=["Bidan & Maps"])
app.include_router(calendar.router, prefix="/calendar", tags=["Calendar"])
app.include_router(profile.router, prefix="/profile", tags=["Profile"])

@app.get("/")
def root():
    return {"message": "JaninSehat API aktif 🚀"}
