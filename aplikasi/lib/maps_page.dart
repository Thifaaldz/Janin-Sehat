import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  List<Map<String, dynamic>> bidans = [];
  Map<String, dynamic>? selectedBidan;

  LatLng userPos = LatLng(-6.2, 106.8); // posisi default (Jakarta)
  List<LatLng> routePoints = [];
  double? distanceKm;

  @override
  void initState() {
    super.initState();
    fetchBidanList();
  }

  Future<void> fetchBidanList() async {
    try {
      final res = await http.get(Uri.parse("${AppConfig.backendBase}/bidan/bidan_list"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          bidans = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint("Error fetch bidan list: $e");
    }
  }

  Future<void> fetchRoute() async {
    if (selectedBidan == null) return;
    final url =
        "${AppConfig.backendBase}/bidan/route?user_lat=${userPos.latitude}&user_lon=${userPos.longitude}&bidan_id=${selectedBidan!["id"]}";

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          distanceKm = data["dist_km"];
          routePoints = (data["path"] as List)
              .map<LatLng>((p) => LatLng(p["lat"], p["lon"]))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetch route: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kontrol Ibu Hamil",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 18)),
            SizedBox(height: 4),
            Text("Maps Bidan Terdekat",
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),

      body: Column(
        children: [
          // Peta
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: userPos,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.janinsehat',
                ),
                MarkerLayer(
                  markers: [
                    // marker user
                    Marker(
                      point: userPos,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.person_pin_circle,
                          color: Colors.blue, size: 40),
                    ),
                    // marker bidan
                    ...bidans.map((b) => Marker(
                          point: LatLng(b["lat"], b["lon"]),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 36),
                        )),
                  ],
                ),
                if (routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                          points: routePoints,
                          color: Colors.teal,
                          strokeWidth: 4)
                    ],
                  ),
              ],
            ),
          ),

          if (distanceKm != null && selectedBidan != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "🚗 Jarak ke ${selectedBidan!["name"]}: ${distanceKm!.toStringAsFixed(2)} km",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),

          // Daftar Bidan
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: bidans.length,
              itemBuilder: (ctx, i) {
                final b = bidans[i];
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.local_hospital,
                        color: Colors.redAccent),
                    title: Text(b["name"]),
                    subtitle: Text("${b["address"]}\n📞 ${b["phone"]}"),
                    onTap: () {
                      setState(() {
                        selectedBidan = b;
                        routePoints = [];
                        distanceKm = null;
                      });
                      fetchRoute();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
