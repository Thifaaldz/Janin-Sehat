// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart'; // Import baseUrl

class ApiService {
  // ✅ Ambil semua data bidan
  Future<List<dynamic>> getBidan() async {
    final response = await http.get(Uri.parse("$baseUrl/bidan"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal memuat data bidan (Status: ${response.statusCode})");
    }
  }

  // ✅ Ambil profil user berdasarkan ID
  Future<Map<String, dynamic>> getProfile(int userId) async {
    final response = await http.get(Uri.parse("$baseUrl/profile/$userId"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal memuat profil (Status: ${response.statusCode})");
    }
  }

  // ✅ Perbarui HPHT pengguna
  Future<void> updateHpht(int userId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse("$baseUrl/profile/$userId/update_hpht"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception("Gagal memperbarui HPHT (Status: ${response.statusCode})");
    }
  }

  // ✅ Ambil jadwal kehamilan berdasarkan user dan HPHT
  Future<List<dynamic>> getCalendarSchedule({
    required int userId,
    required String hptp,
  }) async {
    final response = await http.get(Uri.parse(
        "$baseUrl/calendar/schedule?user_id=$userId&hptp=$hptp"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal memuat jadwal (Status: ${response.statusCode})");
    }
  }
}
