# 🌸 MomCare

Aplikasi mobile untuk membantu ibu hamil dalam mengontrol kehamilan, menemukan bidan terdekat, serta mengatur jadwal checkup.  
Dibangun dengan **Flutter (Dart)** di sisi frontend dan **FastAPI (Python)** di sisi backend.

---

## 🗺️ Sistem Rute Bidan
Sistem **“Rute Bidan”** merupakan sistem informasi berbasis **client-server** yang dirancang untuk:
- Membantu pengguna menemukan bidan terdekat.
- Menghitung **rute tercepat** dari lokasi pengguna ke bidan.
- Menampilkan jarak tempuh secara real-time.

### ⚙️ Arsitektur
- **Backend**:  
  - Dibangun dengan [FastAPI](https://fastapi.tiangolo.com/).  
  - Data bidan dikelola dari file **CSV**.  
  - Jaringan jalan dimodelkan dengan **GeoJSON** yang dibuat/diolah menggunakan **QGIS**.  
  - Jalur tercepat dihitung dengan **algoritma Dijkstra**.  
  - Jika jaringan jalan tidak tersedia, sistem otomatis menggunakan **jalur garis lurus** sebagai alternatif.

- **Frontend (Aplikasi MomCare)**:  
  - Dibangun dengan [Flutter](https://flutter.dev/) menggunakan **Dart**.  
  - Menyediakan **peta interaktif** dengan marker lokasi pengguna & bidan.  
  - Visualisasi rute menggunakan **Polyline** dan menampilkan informasi jarak tempuh.  
  - Multi-platform: **Linux, Web, dan Android Emulator**.  
  - Komunikasi antara frontend dan backend menggunakan **REST API**.

---

## ✨ Fitur Utama
- 📍 **Maps Bidan Terdekat** dengan rute tercepat.
- 🏠 **Homepage Informasi** tentang kontrol ibu hamil.
- 📅 **Kalender** untuk mencatat jadwal checkup.
- 🔔 **Notifikasi** pengingat.
- 💬 **Kontak Bidan** via WhatsApp.

---

## 🚀 Teknologi yang Digunakan
- **Frontend**: Flutter (Dart)  
  - [flutter_map](https://pub.dev/packages/flutter_map) → peta interaktif  
  - [latlong2](https://pub.dev/packages/latlong2) → koordinat  
  - [http](https://pub.dev/packages/http) → komunikasi API  
  - [animations](https://pub.dev/packages/animations) → transisi halaman  

- **Backend**: Python (FastAPI)  
  - CSV untuk data bidan  
  - GeoJSON (dari QGIS) untuk model jaringan jalan  
  - Algoritma Dijkstra untuk perhitungan rute  

---

## 📱 Screenshots

Berikut adalah tampilan aplikasi **MomCare**:

| SplashScreen | HomePage | Maps Page |
|--------------|----------|-----------|
| <img src="assets/main.png" alt="SplashScreen" width="250"/> | <img src="assets/homepage.png" alt="HomePage" width="250"/> | <img src="assets/maps.png" alt="MapsPage" width="250"/> |
# Janin-Sehat
# Janin-Sehat
