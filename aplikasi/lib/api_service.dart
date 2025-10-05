import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://10.0.2.2:9000"; // Emulator Android

  Future<List<dynamic>> getBidan() async {
    final response = await http.get(Uri.parse("$baseUrl/bidan"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal memuat data bidan");
    }
  }
}
