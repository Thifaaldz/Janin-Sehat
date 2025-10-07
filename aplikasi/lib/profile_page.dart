import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  final int userId;
  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> fetalGrowth = [];
  bool loading = true;

  late String baseUrl;

  @override
  void initState() {
    super.initState();
    // Pilih base URL tergantung platform
    if (Platform.isAndroid) {
      baseUrl = 'http://10.0.2.2:9000';
    } else {
      baseUrl = 'http://127.0.0.1:9000';
    }
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl/profile/${widget.userId}'));
      if (resp.statusCode != 200) throw Exception("Gagal memuat data profil");
      final data = json.decode(resp.body);

      setState(() {
        userData = data["user"];
        fetalGrowth = List<Map<String, dynamic>>.from(data["fetal_growth"]);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      debugPrint("❌ Gagal fetch data profil: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil data profil: $e")),
      );
    }
  }

  // ------------------- Tambah Data Janin -------------------
  Future<void> addGrowthDialog() async {
    final weekController = TextEditingController();
    final weightController = TextEditingController();
    final lengthController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Tambah Data Perkembangan Janin"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: weekController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Minggu ke-"),
              ),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Berat Janin (gram)"),
              ),
              TextField(
                controller: lengthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Panjang Janin (cm)"),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: "Catatan tambahan (opsional)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveGrowth(
                week: int.tryParse(weekController.text) ?? 0,
                weight: double.tryParse(weightController.text) ?? 0,
                length: double.tryParse(lengthController.text) ?? 0,
                notes: notesController.text,
              );
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGrowth({
    required int week,
    required double weight,
    required double length,
    required String notes,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/profile/${widget.userId}/growth'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "week": week,
          "fetalWeight": weight,
          "fetalLength": length,
          "notes": notes,
        }),
      );

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Data perkembangan berhasil disimpan")),
        );
        fetchProfile();
      } else {
        final err = json.decode(resp.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Gagal: ${err["detail"] ?? "Terjadi kesalahan"}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  // ------------------- Update Profil -------------------
  Future<void> editProfileDialog() async {
    final nameController = TextEditingController(text: userData?["name"] ?? "");
    final emailController = TextEditingController(text: userData?["email"] ?? "");
    final bpController = TextEditingController(text: userData?["bloodPressure"]?.toString() ?? "");
    final hrController = TextEditingController(text: userData?["heartRate"]?.toString() ?? "");
    final weekController = TextEditingController(text: userData?["gestationalWeek"]?.toString() ?? "");

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Profil Pasien"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nama")),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
              TextField(
                controller: weekController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Minggu Kehamilan"),
              ),
              TextField(controller: bpController, decoration: const InputDecoration(labelText: "Tekanan Darah")),
              TextField(
                controller: hrController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Denyut Jantung (bpm)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              await _updateProfile(
                name: nameController.text,
                email: emailController.text,
                gestationalWeek: int.tryParse(weekController.text) ?? 0,
                bloodPressure: bpController.text,
                heartRate: int.tryParse(hrController.text) ?? 0,
              );
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile({
    required String name,
    required String email,
    required int gestationalWeek,
    required String bloodPressure,
    required int heartRate,
  }) async {
    try {
      final resp = await http.put(
        Uri.parse('$baseUrl/profile/update/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "name": name,
          "email": email,
          "gestationalWeek": gestationalWeek,
          "bloodPressure": bloodPressure,
          "heartRate": heartRate,
        }),
      );

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Profil berhasil diperbarui")),
        );
        fetchProfile();
      } else {
        final err = json.decode(resp.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Gagal update: ${err["detail"] ?? "Terjadi kesalahan"}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error update: $e")),
      );
    }
  }

  // ------------------- UI -------------------
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (userData == null) {
      return const Scaffold(body: Center(child: Text("⚠️ Tidak ada data profil")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Pasien"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: const Icon(Icons.edit), tooltip: "Edit Profil", onPressed: editProfileDialog),
          IconButton(icon: const Icon(Icons.add_circle_outline), tooltip: "Tambah perkembangan", onPressed: addGrowthDialog),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 50, backgroundImage: AssetImage("assets/mom.jpg")),
                      const SizedBox(height: 12),
                      Text(userData!["name"] ?? "Nama tidak tersedia",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      Text(userData!["email"] ?? "", style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _infoTile("Minggu", "${userData!["gestationalWeek"] ?? '-'}"),
                          _infoTile("Tekanan Darah", "${userData!["bloodPressure"] ?? '-'}"),
                          _infoTile("Denyut Jantung", "${userData!["heartRate"] ?? '-'} bpm"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Perkembangan Janin per Minggu",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(height: 10),
              if (fetalGrowth.isEmpty)
                const Text("Belum ada data perkembangan."),
              ...fetalGrowth.map((f) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: Text("${f["week"]}"),
                      ),
                      title: Text(
                          "Minggu ke-${f["week"]}: ${f["fetal_weight"] ?? f["fetalWeight"] ?? 0} g, ${f["fetal_length"] ?? f["fetalLength"] ?? 0} cm"),
                      subtitle: Text(f["notes"] ?? "-"),
                      trailing: Text(
                        (f["created_at"] ?? "").toString().split(" ")[0],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
