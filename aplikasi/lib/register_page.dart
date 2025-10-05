import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _gestationalWeekController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bloodPressureController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _hptpController = TextEditingController(); // ➕ HPTP controller

  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = Uri.parse("http://127.0.0.1:9000/auth/register");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": _nameController.text,
        "email": _emailController.text,
        "password": _passwordController.text,
        "gestationalWeek": int.tryParse(_gestationalWeekController.text) ?? 1,
        "weight": double.tryParse(_weightController.text) ?? 0,
        "height": double.tryParse(_heightController.text) ?? 0,
        "bloodPressure": _bloodPressureController.text,
        "heartRate": int.tryParse(_heartRateController.text) ?? 0,
        "hptp": _hptpController.text, // ➕ kirim ke API
      }),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      // ✅ Registrasi sukses → kembali ke login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registrasi berhasil, silakan login")),
      );
      Navigator.pushReplacementNamed(context, "/login");
    } else {
      // ❌ gagal
      try {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal daftar: ${err["detail"]}")),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal daftar, coba lagi")),
        );
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType? type,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: type ?? TextInputType.text,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return "$label tidak boleh kosong";
        return null;
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale("id", "ID"), // bahasa Indonesia
    );
    if (picked != null) {
      setState(() {
        _hptpController.text =
            picked.toIso8601String().split("T")[0]; // YYYY-MM-DD
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Akun"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(label: "Nama", controller: _nameController),
              const SizedBox(height: 12),
              _buildTextField(
                  label: "Email",
                  controller: _emailController,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildTextField(
                  label: "Password",
                  controller: _passwordController,
                  isPassword: true),
              const SizedBox(height: 12),
              _buildTextField(
                  label: "Minggu Kehamilan",
                  controller: _gestationalWeekController,
                  type: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(
                  label: "Berat (kg)",
                  controller: _weightController,
                  type: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(
                  label: "Tinggi (cm)",
                  controller: _heightController,
                  type: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(
                  label: "Tekanan Darah",
                  controller: _bloodPressureController),
              const SizedBox(height: 12),
              _buildTextField(
                  label: "Denyut Jantung",
                  controller: _heartRateController,
                  type: TextInputType.number),
              const SizedBox(height: 12),

              // ➕ input tanggal HPTP
              _buildTextField(
                label: "HPTP (Hari Pertama Haid Terakhir)",
                controller: _hptpController,
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Daftar",
                          style:
                              TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
