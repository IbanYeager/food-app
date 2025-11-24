// ===== lib/screens/courier/courier_active_delivery_screen.dart =====
import 'dart:async';
import 'package:flutter/material.dart';
// 💡 Import Peta Gratis (Flutter Map)
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

// Import Service & Screen Lain
import 'package:test_application/services/delivery_service.dart';
import 'package:test_application/services/route_service.dart';
import 'package:test_application/services/location_service.dart';
import 'package:test_application/screens/chat_screen.dart';
// 💡 IMPORT WIDGET BARU
import 'package:test_application/widgets/photo_marker.dart';

class CourierActiveDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const CourierActiveDeliveryScreen({super.key, required this.order});

  @override
  State<CourierActiveDeliveryScreen> createState() =>
      _CourierActiveDeliveryScreenState();
}

class _CourierActiveDeliveryScreenState
    extends State<CourierActiveDeliveryScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  final LocationService _locationService = LocationService();

  // 💡 Controller Peta Gratis
  final MapController _mapController = MapController();

  // Variabel Lokasi
  latlong.LatLng? _courierLocation;
  late latlong.LatLng _restaurantLocation;
  late latlong.LatLng _customerLocation;

  List<latlong.LatLng> _routePoints = [];

  // Stream Lokasi Real-time
  StreamSubscription<Position>? _positionStream;

  bool _isDelivering = false;
  String _statusMessage = "Siap mengambil pesanan...";
  int _courierId = 0;

  // 💡 Variabel untuk Foto Customer
  String? _customerPhotoUrl;

  @override
  void initState() {
    super.initState();
    // Inisialisasi Lokasi Resto & Customer dari data Order
    _restaurantLocation = latlong.LatLng(
      double.parse(widget.order['origin_lat'].toString()),
      double.parse(widget.order['origin_lng'].toString()),
    );
    _customerLocation = latlong.LatLng(
      double.parse(widget.order['destination_lat'].toString()),
      double.parse(widget.order['destination_lng'].toString()),
    );

    // 💡 AMBIL FOTO USER DARI DATA ORDER (Jika ada)
    // Pastikan API get_courier_tasks.php mengirimkan field 'foto_user' (nama file)
    // Jika tidak ada, akan otomatis pakai default image dari PhotoMarker
    if (widget.order['foto_user'] != null && widget.order['foto_user'].toString().isNotEmpty) {
       _customerPhotoUrl = "http://192.168.1.6/test_application/uploads/${widget.order['foto_user']}";
    }

    _initializeCourier();
  }

  @override
  void dispose() {
    _positionStream?.cancel(); // Hentikan update lokasi saat keluar
    super.dispose();
  }

  Future<void> _initializeCourier() async {
    final prefs = await SharedPreferences.getInstance();
    _courierId = prefs.getInt('user_id') ?? 0;

    try {
      final locationData = await _locationService.getCurrentLocation();
      final Position position = locationData['position'];
      if (mounted) {
        setState(() {
          _courierLocation = latlong.LatLng(position.latitude, position.longitude);
        });
        // Rute awal: Kurir -> Restoran
        _getRoute(_courierLocation!, _restaurantLocation);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = "Gagal mendapatkan lokasi. Nyalakan GPS.";
          _courierLocation = null;
        });
      }
    }
  }

  Future<void> _getRoute(latlong.LatLng from, latlong.LatLng to) async {
    try {
      final points = await RouteService.getRoute(from, to);
      if (mounted) {
        setState(() {
          _routePoints = points;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil rute: $e");
    }
  }

  Future<void> _startDelivery() async {
    if (_courierId == 0) {
      setState(() => _statusMessage = "Error: ID Kurir tidak ditemukan.");
      return;
    }

    setState(() => _statusMessage = "Memulai pengantaran...");

    final result = await _deliveryService.startDelivery(
      widget.order['order_number'],
      _courierId,
    );

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _isDelivering = true;
          _statusMessage = "Dalam perjalanan ke lokasi pelanggan...";
        });
        // Update rute: Restoran -> Pelanggan
        _getRoute(_restaurantLocation, _customerLocation);

        // Mulai dengarkan pergerakan Kurir
        _positionStream = Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update tiap 10 meter
        )).listen((Position position) {
          if (mounted) {
            final newCourierLocation =
                latlong.LatLng(position.latitude, position.longitude);
            setState(() {
              _courierLocation = newCourierLocation;
            });
            
            // Update rute dinamis (Kurir -> Pelanggan)
            // _getRoute(newCourierLocation, _customerLocation); // Opsional: Aktifkan jika ingin rute selalu update
            
            // Gerakkan kamera mengikuti kurir
            _mapController.move(newCourierLocation, _mapController.camera.zoom);
          }
        });
      } else {
        setState(() {
          _statusMessage = "Gagal memulai: ${result['message']}";
        });
      }
    }
  }

  Future<void> _stopDelivery() async {
    // Tampilkan Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Panggil API Selesai
    bool success = await _deliveryService.finishDelivery(widget.order['order_number']);
    
    if (mounted) Navigator.pop(context); // Tutup loading

    if (success) {
      _positionStream?.cancel();
      _deliveryService.stopDelivery();
      
      if (mounted) {
        setState(() {
          _isDelivering = false;
          _statusMessage = "Pesanan Selesai!";
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pesanan berhasil diselesaikan!"), backgroundColor: Colors.green),
        );

        Navigator.pop(context); // Kembali ke Dashboard
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menyelesaikan pesanan. Coba lagi.")),
        );
      }
    }
  }

  // Helper membuat Marker
  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];

    // 1. Restoran
    markers.add(Marker(
      point: _restaurantLocation,
      width: 80,
      height: 80,
      child: const Icon(Icons.store, color: Colors.orange, size: 40),
    ));

    // 2. Pelanggan (💡 GANTI DENGAN FOTO PROFIL)
    markers.add(PhotoMarker(
      point: _customerLocation,
      photoUrl: _customerPhotoUrl,
      isDriver: false, // Warna Biru
    ));

    // 3. Kurir (Jika lokasi ada)
    if (_courierLocation != null) {
      markers.add(Marker(
        point: _courierLocation!,
        width: 80,
        height: 80,
        child: const Icon(Icons.delivery_dining, color: Colors.green, size: 40),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Antar #${widget.order['order_number']}"),
      ),
      body: Column(
        children: [
          // --- BAGIAN PETA ---
          Expanded(
            child: _courierLocation == null
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _courierLocation!,
                      initialZoom: 14.5,
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
                      // Marker (Ikon Lokasi)
                      MarkerLayer(
                        markers: _buildMarkers(),
                      ),
                    ],
                  ),
          ),
          
          // --- PANEL BAWAH (INFO & TOMBOL) ---
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Tujuan: ${widget.order['nama_user']}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "HP: ${widget.order['no_hp_user']}",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(_statusMessage,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    // Tombol Mulai/Selesai Antar
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isDelivering ? Colors.red : Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          if (_isDelivering) {
                            _stopDelivery();
                          } else {
                            _startDelivery();
                          }
                        },
                        child: Text(
                          _isDelivering ? "Selesai Antar" : "Mulai Antar",
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    
                    // Tombol Chat
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.all(16),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              orderNumber: widget.order['order_number'],
                              currentUserRole: 'courier',
                            ),
                          ),
                        );
                      },
                      child: const Icon(Icons.chat, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}