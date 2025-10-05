from pydantic import BaseModel
from datetime import date

class UserRegister(BaseModel):
    name: str
    email: str
    password: str
    gestationalWeek: int | None = 1
    weight: float | None = 0
    height: float | None = 0
    bloodPressure: str | None = ""
    heartRate: int | None = 0
    hptp: date | None = None         # Hari Pertama Haid Terakhir
    dueDate: date | None = None      # Perkiraan Tanggal Lahir

class UserLogin(BaseModel):
    email: str
    password: str
