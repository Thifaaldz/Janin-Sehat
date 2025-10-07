import sqlite3

DB_PATH = "momcare.db"

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    # ✅ Tabel users
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
            hptp TEXT,        -- HPHT
            dueDate TEXT      -- Tanggal perkiraan lahir
        )
    """)

    # ✅ Tabel perkembangan janin mingguan
    conn.execute("""
        CREATE TABLE IF NOT EXISTS fetal_growth (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            week INTEGER NOT NULL,
            fetal_weight REAL,
            fetal_length REAL,
            notes TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
    """)

    conn.commit()
    conn.close()
