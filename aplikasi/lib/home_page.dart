import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatefulWidget {
  final int userId;
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? mlResult;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }
  
  Future<void> fetchUserData() async {
    try {
      final resp = await http
          .get(Uri.parse('http://127.0.0.1:9000/home/${widget.userId}'));
      if (resp.statusCode != 200) throw Exception("Gagal ambil data");
      final data = json.decode(resp.body);

      setState(() {
        userData = data["profile"];
        mlResult = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      debugPrint("Error fetch data: $e");
    }
  }

  Future<void> _openWithWslView(String url) async {
    try {
      final result = await Process.run('wslview', [url]);
      if (result.exitCode != 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("wslview gagal: ${result.stderr}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error buka link: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (userData == null || mlResult == null) {
      return const Center(child: Text("⚠️ Gagal memuat data"));
    }

    // Data dari backend
    final anomalies = mlResult!["rule_anomalies"] ?? [];
    final recommendations = List<String>.from(mlResult!["recommendations"] ?? []);
    final articles = List<Map<String, dynamic>>.from(mlResult!["articles"] ?? []);
    final growthChart =
        List<Map<String, dynamic>>.from(mlResult!["growth_chart"] ?? []);
    final patientPoint = mlResult!["patient_point"];

    final week = userData!["gestationalWeek"];
    final weight = userData!["weight"];
    final height = userData!["height"];
    final bp = userData!["bloodPressure"];
    final hr = userData!["heartRate"];
    final name = userData!["name"];

    final patientWeight = (patientPoint["weight"] as num).toDouble();
    final patientHeight = (patientPoint["height"] as num).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profil Ibu
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const CircleAvatar(
                  radius: 28, backgroundImage: AssetImage("assets/mom.jpg")),
              title: Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text("Kehamilan Minggu ke-$week"),
            ),
          ),
          const SizedBox(height: 20),

          // Status Kesehatan
          const Text("Status Kesehatan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatusCard("Berat Badan", "$weight kg", Icons.monitor_weight,
                  userData!["weight_status"]),
              _StatusCard("Tinggi Badan", "$height cm", Icons.height,
                  userData!["height_status"]),
              _StatusCard(
                  "Tekanan Darah", bp, Icons.bloodtype, "normal"), // placeholder
              _StatusCard("Denyut Jantung", "$hr bpm", Icons.favorite,
                  userData!["heartRate_status"]),
            ],
          ),
          const SizedBox(height: 24),

          // Monitoring Janin
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text("Monitoring Terbaru",
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("$week minggu",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.teal)),
                  const SizedBox(height: 12),
                  Image.asset("assets/baby.png", height: 140),
                  const SizedBox(height: 8),
                  Text("Panjang: $height cm, berat badan: $weight kg",
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  if (anomalies.isNotEmpty) ...[
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Deteksi Anomali:",
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(height: 6),
                    ...anomalies.map<Widget>((a) => Text("• $a")).toList(),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Grafik Perkembangan Janin
          const Text("Grafik Perkembangan Janin",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
                titlesData: FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: true)),
                ),
                lineBarsData: [
                  // Garis standar berat
                  LineChartBarData(
                    spots: growthChart
                        .map((e) => FlSpot((e["week"] as num).toDouble(),
                            (e["weight_max"] as num).toDouble()))
                        .toList(),
                    isCurved: true,
                    color: Colors.blue,
                    dotData: FlDotData(show: false),
                  ),
                  // Garis standar panjang
                  LineChartBarData(
                    spots: growthChart
                        .map((e) => FlSpot((e["week"] as num).toDouble(),
                            (e["height_max"] as num).toDouble()))
                        .toList(),
                    isCurved: true,
                    color: Colors.green,
                    dotData: FlDotData(show: false),
                  ),
                  // Titik pasien berat
                  LineChartBarData(
                    spots: [FlSpot(week.toDouble(), patientWeight)],
                    isCurved: false,
                    color: Colors.red,
                    barWidth: 0,
                    dotData: FlDotData(show: true),
                  ),
                  // Titik pasien panjang
                  LineChartBarData(
                    spots: [FlSpot(week.toDouble(), patientHeight)],
                    isCurved: false,
                    color: Colors.orange,
                    barWidth: 0,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Text(
                "🔵 Berat standar | 🟢 Panjang standar | 🔴 Berat pasien | 🟠 Panjang pasien"),
          ]),
          const SizedBox(height: 24),

          // Rekomendasi
          const Text("Rekomendasi Minggu Ini",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          ...recommendations.map((r) => ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(r),
              )),

          const SizedBox(height: 24),

          // Artikel
          const Text("Artikel Rekomendasi",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          ...articles.map((a) => ListTile(
                leading: const Icon(Icons.article, color: Colors.teal),
                title: Text(a["title"]),
                subtitle: Text(a["url"]),
                trailing: const Icon(Icons.open_in_new, color: Colors.grey),
                onTap: () => _openWithWslView(a["url"].toString().trim()),
              )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String status;

  const _StatusCard(this.label, this.value, this.icon, this.status);

  @override
  Widget build(BuildContext context) {
    final isAbnormal = status == "abnormal";
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isAbnormal ? Colors.red.shade100 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: isAbnormal ? Colors.red : Colors.teal),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isAbnormal ? Colors.red : Colors.black,
                )),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isAbnormal ? Colors.red : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
