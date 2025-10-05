from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.db import init_db
from app.routes import auth, home, bidan, calendar   # ✅ tambahkan calendar di sini

app = FastAPI(title="MomCare API")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Init DB
init_db()

# Routes
app.include_router(auth.router, prefix="/auth", tags=["Auth"])
app.include_router(home.router, prefix="/home", tags=["Home"])
app.include_router(bidan.router, prefix="/bidan", tags=["Bidan & Maps"])
app.include_router(calendar.router, prefix="/calendar", tags=["Calendar"])  # ✅ sudah benar
