import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final String apiBaseUrl = "http://10.0.2.2:9000"; // Android Emulator -> backend
  late GoogleMapController mapController;
  LatLng? userLocation;
  LatLng? bidanLocation;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  List<String> bidanList = [];
  String selectedBidan = "";
  double? distanceKm;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    fetchBidanList();
  }

  Future<void> _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> fetchBidanList() async {
    final url = Uri.parse("$apiBaseUrl/bidan_names");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        bidanList = data.cast<String>();
      });
    }
  }

  Future<void> fetchRoute() async {
    if (selectedBidan.isEmpty || userLocation == null) return;

    final url = Uri.parse(
      "$apiBaseUrl/route?user_lat=${userLocation!.latitude}&user_lon=${userLocation!.longitude}&bidan_name=$selectedBidan",
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final double dist = data["dist_km"];
      final double destLat = data["dest"]["lat"];
      final double destLon = data["dest"]["lon"];
      final List<dynamic> route = data["path"];

      final LatLng dest = LatLng(destLat, destLon);

      setState(() {
        distanceKm = dist;
        bidanLocation = dest;

        markers = {
          Marker(
            markerId: const MarkerId("user"),
            position: userLocation!,
            infoWindow: const InfoWindow(title: "Anda"),
          ),
          Marker(
            markerId: const MarkerId("bidan"),
            position: dest,
            infoWindow: InfoWindow(title: selectedBidan),
          ),
        };

        polylines = {
          Polyline(
            polylineId: const PolylineId("route"),
            color: Colors.green,
            width: 5,
            points: route
                .map((p) => LatLng(p["lat"], p["lon"]))
                .toList()
                .cast<LatLng>(),
          )
        };
      });

      mapController.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            (userLocation!.latitude < dest.latitude) ? userLocation!.latitude : dest.latitude,
            (userLocation!.longitude < dest.longitude) ? userLocation!.longitude : dest.longitude,
          ),
          northeast: LatLng(
            (userLocation!.latitude > dest.latitude) ? userLocation!.latitude : dest.latitude,
            (userLocation!.longitude > dest.longitude) ? userLocation!.longitude : dest.longitude,
          ),
        ),
        50,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("JaninSehat - Rute ke Bidan"),
      ),
      body: Column(
        children: [
          if (bidanList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                value: selectedBidan.isEmpty ? null : selectedBidan,
                hint: const Text("Pilih Bidan"),
                items: bidanList.map((b) {
                  return DropdownMenuItem(value: b, child: Text(b));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedBidan = val!;
                  });
                  fetchRoute();
                },
              ),
            ),
          if (distanceKm != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Jarak: ${distanceKm!.toStringAsFixed(2)} km"),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(-6.2, 106.8), // default Jakarta
                zoom: 12,
              ),
              markers: markers,
              polylines: polylines,
              myLocationEnabled: true,
              onMapCreated: (controller) => mapController = controller,
            ),
          ),
        ],
      ),
    );
  }
}
