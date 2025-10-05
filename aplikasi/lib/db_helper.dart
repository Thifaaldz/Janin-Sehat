import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  initDb() async {
    String path = join(await getDatabasesPath(), "momcare.db");
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute("""
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          email TEXT UNIQUE,
          password TEXT,
          gestationalWeek INTEGER,
          weight REAL,
          height REAL,
          bloodPressure TEXT,
          heartRate INTEGER
        )
      """);
    });
  }

  Future<int> insertUser(Map<String, dynamic> data) async {
    final dbClient = await db;
    return await dbClient.insert("users", data);
  }

  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final dbClient = await db;
    final res = await dbClient.query(
      "users",
      where: "email = ? AND password = ?",
      whereArgs: [email, password],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }
}
