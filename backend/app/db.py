import sqlite3

DB_PATH = "momcare.db"

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    conn.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            gestationalWeek INTEGER,
            weight REAL,
            height REAL,
            bloodPressure TEXT,
            heartRate INTEGER,
            hptp TEXT,        -- simpan sebagai string ISO (YYYY-MM-DD)
            dueDate TEXT      -- simpan sebagai string ISO (YYYY-MM-DD)
        )
    """)
    conn.commit()
    conn.close()
