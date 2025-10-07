// lib/config/api.dart
// ✅ Ganti IP di bawah ini dengan IP LAN dari host tempat backend FastAPI berjalan.
// ⚠️ Jangan gunakan 10.0.2.2 jika backend berjalan di WSL atau environment lain.
// Contoh: hasil dari `ipconfig` di Windows atau `ip addr` di Linux.

const String baseUrl = "http://192.168.1.100:9000"; // Ganti sesuai IP host kamu
