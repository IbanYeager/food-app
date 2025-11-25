import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart' as latlong; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

// Import Service & Screen Lain
import 'package:test_application/services/delivery_service.dart';
import 'package:test_application/services/route_service.dart';
import 'package:test_application/services/location_service.dart';
import 'package:test_application/screens/chat_screen.dart';
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
  final MapController _mapController = MapController();

  // --- LOKASI ---
  latlong.LatLng? _courierLocation;
  late latlong.LatLng _restaurantLocation; // Titik Awal (Toko)
  late latlong.LatLng _customerLocation;   // Titik Akhir (Pelanggan)
  
  List<latlong.LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStream;

  // Status
  bool _isDelivering = false; // True jika status 'on_delivery'
  String _statusMessage = "Menyiapkan data...";
  int _courierId = 0;
  String? _customerPhotoUrl;

  @override
  void initState() {
    super.initState();
    
    // 1. Setup Koordinat
    _restaurantLocation = latlong.LatLng(
      double.tryParse(widget.order['origin_lat'].toString()) ?? 0.0,
      double.tryParse(widget.order['origin_lng'].toString()) ?? 0.0,
    );
    _customerLocation = latlong.LatLng(
      double.tryParse(widget.order['destination_lat'].toString()) ?? 0.0,
      double.tryParse(widget.order['destination_lng'].toString()) ?? 0.0,
    );

    // 2. Cek Status Awal
    String currentStatus = widget.order['status'] ?? '';
    if (currentStatus == 'on_delivery') {
      _isDelivering = true;
      _statusMessage = "Sedang mengantar ke pelanggan...";
    } else {
      _isDelivering = false;
      _statusMessage = "Pesanan siap diantar.";
    }

    // 3. Foto Customer
    if (widget.order['foto_user'] != null && widget.order['foto_user'].toString().isNotEmpty) {
       // Ganti IP sesuai server Anda
       _customerPhotoUrl = "http://192.168.1.7/test_application/uploads/${widget.order['foto_user']}";
    }

    _initializeCourier();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initializeCourier() async {
    final prefs = await SharedPreferences.getInstance();
    _courierId = prefs.getInt('user_id') ?? 0;

    try {
      // Ambil lokasi kurir saat ini
      final locationData = await _locationService.getCurrentLocation();
      final Position position = locationData['position'];
      
      if (mounted) {
        setState(() {
          _courierLocation = latlong.LatLng(position.latitude, position.longitude);
        });
        
        // --- LOGIKA SINGLE STORE ---
        // Rute selalu dari Toko ke Pelanggan (karena kurir standby di toko)
        _getRoute(_restaurantLocation, _customerLocation);
        
        // Jika sudah on_delivery, nyalakan tracking realtime
        if (_isDelivering) {
          _startLocationTracking();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = "Gagal mendapatkan lokasi GPS.");
    }
  }

  Future<void> _getRoute(latlong.LatLng from, latlong.LatLng to) async {
    try {
      final points = await RouteService.getRoute(from, to);
      if (mounted) {
        setState(() {
          _routePoints = points;
        });
        _fitCamera(points); 
      }
    } catch (e) {
      debugPrint("Gagal mengambil rute: $e");
    }
  }

  void _fitCamera(List<latlong.LatLng> points) {
    if (points.isEmpty) return;

    try {
        double minLat = points.first.latitude;
        double maxLat = points.first.latitude;
        double minLng = points.first.longitude;
        double maxLng = points.first.longitude;

        for (var p in points) {
          if (p.latitude < minLat) minLat = p.latitude;
          if (p.latitude > maxLat) maxLat = p.latitude;
          if (p.longitude < minLng) minLng = p.longitude;
          if (p.longitude > maxLng) maxLng = p.longitude;
        }

        // Menggunakan LatLngBounds dari flutter_map
        final bounds = LatLngBounds(
          latlong.LatLng(minLat, minLng), // SouthWest
          latlong.LatLng(maxLat, maxLng), // NorthEast
        );

        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50), 
          ),
        );
    } catch(e) { 
      debugPrint("Error fitting camera: $e");
    }
  }

  // --- LOGIKA TOMBOL UTAMA ---
  Future<void> _handleButtonAction() async {
    if (!_isDelivering) {
        // STATUS: READY -> ON_DELIVERY
        await _startDeliveryProcess();
    } else {
        // STATUS: ON_DELIVERY -> COMPLETED
        await _finishDeliveryProcess();
    }
  }

  Future<void> _startDeliveryProcess() async {
    if (_courierId == 0) return;
    setState(() => _statusMessage = "Memulai pengantaran...");

    // Panggil API update status ke 'on_delivery'
    final result = await _deliveryService.startDelivery(
      widget.order['order_number'],
      _courierId,
    );

    if (result['success'] == true) {
        if (mounted) {
            setState(() {
                _isDelivering = true;
                _statusMessage = "Menuju ke Pelanggan...";
            });
            _startLocationTracking(); // Mulai update lokasi realtime ke server
        }
    } else {
        setState(() => _statusMessage = "Gagal: ${result['message']}");
    }
  }

  Future<void> _finishDeliveryProcess() async {
      bool confirm = await showDialog(
          context: context, 
          builder: (ctx) => AlertDialog(
              title: const Text("Selesaikan Pesanan"),
              content: const Text("Pastikan pesanan sudah diterima pelanggan."),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true), 
                      child: const Text("Selesai")
                  )
              ],
          )
      ) ?? false;

      if (!confirm) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Panggil API update status ke 'completed'
      bool success = await _deliveryService.finishDelivery(widget.order['order_number']);
      
      if (mounted) Navigator.pop(context); 

      if (success) {
          _positionStream?.cancel();
          _deliveryService.stopDelivery();
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pesanan Selesai!"), backgroundColor: Colors.green));
              Navigator.pop(context, true); // Kembali ke Dashboard dengan reload
          }
      } else {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal update status.")));
      }
  }

  void _startLocationTracking() {
      // Update lokasi setiap 10 meter
      _positionStream = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
      ).listen((Position position) {
          if (mounted) {
              final newLoc = latlong.LatLng(position.latitude, position.longitude);
              setState(() {
                  _courierLocation = newLoc;
              });
              
              // Kirim lokasi ke server (untuk tracking user)
              // Pastikan DeliveryService punya fungsi updateLocation
              // _deliveryService.updateLocation(widget.order['order_number'], position.latitude, position.longitude);
              
              // Opsional: Kamera map mengikuti kurir
              // _mapController.move(newLoc, _mapController.camera.zoom);
          }
      });
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];

    // 1. Marker Restoran (Titik Awal)
    markers.add(Marker(
        point: _restaurantLocation,
        width: 60, height: 60,
        child: const Column(
            children: [
                Icon(Icons.store, color: Colors.orange, size: 40),
                Text("Toko", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: Colors.white))
            ],
        ),
    ));

    // 2. Marker Pelanggan (Titik Akhir)
    markers.add(PhotoMarker(
        point: _customerLocation,
        photoUrl: _customerPhotoUrl,
        isDriver: false, 
    ));

    // 3. Marker Kurir (Posisi Saat Ini)
    if (_courierLocation != null) {
      markers.add(Marker(
        point: _courierLocation!,
        width: 60, height: 60,
        child: const Icon(Icons.delivery_dining, color: Colors.blue, size: 40),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    // Logika Teks Tombol
    String buttonText = "Mulai Pengantaran";
    Color buttonColor = Colors.deepOrange;

    if (_isDelivering) {
        buttonText = "Pesanan Selesai (Sampai)";
        buttonColor = Colors.green;
    }

    return Scaffold(
      appBar: AppBar(title: Text("Order #${widget.order['order_number']}")),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _restaurantLocation, // Start di Toko
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c', 'd'],
                  ),
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(points: _routePoints, color: Colors.blueAccent, strokeWidth: 5),
                      ],
                    ),
                  MarkerLayer(markers: _buildMarkers()),
                ],
              ),
          ),
          
          // PANEL BAWAH
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    children: [
                        const Icon(Icons.person_pin_circle, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                "Antar ke: ${widget.order['nama_user'] ?? 'Pelanggan'}",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                        ),
                    ],
                ),
                const SizedBox(height: 5),
                Text(_statusMessage, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _handleButtonAction,
                        child: Text(
                          buttonText,
                          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Tombol Chat
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                      child: const Icon(Icons.chat, color: Colors.black),
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