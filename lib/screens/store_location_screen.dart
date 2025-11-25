// ===== lib/screens/store_location_screen.dart (LOKASI BANDUNG) =====
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:test_application/services/location_service.dart';
import 'package:test_application/services/route_service.dart';

class StoreLocationScreen extends StatefulWidget {
  const StoreLocationScreen({super.key});

  @override
  State<StoreLocationScreen> createState() => _StoreLocationScreenState();
}

class _StoreLocationScreenState extends State<StoreLocationScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  
  // 💡 KOORDINAT BARU: Alun-Alun Bandung (Pusat Kota)
  final LatLng _storeLocation = const LatLng(-6.9218518, 107.6048254); 
  
  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  String _distanceInfo = "Menghitung jarak...";

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final locationData = await _locationService.getCurrentLocation();
      final Position position = locationData['position'];
      
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        
        // Hitung Rute dari User ke Toko
        _getRoute(_userLocation!, _storeLocation);
        
        // Pindahkan kamera agar Toko terlihat saat pertama kali dibuka
        _mapController.move(_storeLocation, 14.0);
      }
    } catch (e) {
      if (mounted) setState(() => _distanceInfo = "Gagal mendapatkan lokasi Anda");
    }
  }

  Future<void> _getRoute(LatLng from, LatLng to) async {
    try {
      final points = await RouteService.getRoute(from, to);
      
      // Hitung jarak kasar (Euclidean)
      final Distance distance = const Distance();
      final double km = distance.as(LengthUnit.Kilometer, from, to);

      if (mounted) {
        setState(() {
          _routePoints = points;
          _distanceInfo = "Jarak: ${km.toStringAsFixed(1)} km ke Toko";
        });
        
        // Fit Camera agar kedua lokasi (User & Toko) masuk dalam layar
        if (points.isNotEmpty) {
           _fitCamera(points);
        }
      }
    } catch (e) {
      debugPrint("Gagal load rute: $e");
    }
  }

  void _fitCamera(List<LatLng> points) {
    try {
        double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
        for (var p in points) {
          if (p.latitude < minLat) minLat = p.latitude;
          if (p.latitude > maxLat) maxLat = p.latitude;
          if (p.longitude < minLng) minLng = p.longitude;
          if (p.longitude > maxLng) maxLng = p.longitude;
        }
        
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds(
              LatLng(minLat, minLng),
              LatLng(maxLat, maxLng),
            ),
            padding: const EdgeInsets.all(50),
          ),
        );
    } catch(e) {
        // Abaikan
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lokasi Toko (Bandung)")),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _storeLocation,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                // Garis Rute
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Colors.blueAccent,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    // Marker Toko
                    Marker(
                      point: _storeLocation,
                      width: 80,
                      height: 80,
                      child: const Column(
                        children: [
                          Icon(Icons.store, color: Colors.deepOrange, size: 40),
                          Text("Toko", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ),
                    // Marker User
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Restoran Enak Sekali (Cabang Bandung)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text("Jl. Asia Afrika No. 99, Alun-Alun Bandung", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.directions, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(_distanceInfo, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}