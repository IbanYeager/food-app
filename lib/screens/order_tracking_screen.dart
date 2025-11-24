// ===== lib/screens/order_tracking_screen.dart (PERBAIKAN FLUTTER_MAP) =====
import 'dart:convert';
import 'package:flutter/material.dart';
// 💡 1. IMPORT PETA FLUTTER_MAP
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong; // Tipe data lokasi
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:test_application/services/route_service.dart';
import 'package:test_application/screens/chat_screen.dart';
// 💡 IMPORT WIDGET BARU
import 'package:test_application/widgets/photo_marker.dart';

class OrderTrackingScreen extends StatefulWidget {
  // 💡 2. TIPE DATA SUDAH BENAR (latlong.LatLng)
  final latlong.LatLng userLocation; // Lokasi user (tujuan)
  final latlong.LatLng restaurantLocation; // Lokasi awal (asal)
  final String orderNumber;
  final String? courierPhotoUrl; // 💡 TERIMA FOTO KURIR

  const OrderTrackingScreen({
    super.key,
    required this.orderNumber,
    required this.userLocation,
    required this.restaurantLocation,
    this.courierPhotoUrl, // Tambahkan ini
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  // 💡 3. GANTI TIPE DATA CONTROLLER
  final MapController _mapController = MapController();
  latlong.LatLng? _courierLocation; // State untuk lokasi kurir!

  List<latlong.LatLng> _routePoints = [];

  String statusMessage = "Menghubungkan ke server pelacakan...";

  @override
  void initState() {
    super.initState();
    // Lokasi awal kurir adalah lokasi restoran
    _courierLocation = widget.restaurantLocation;

    _initPusher();
    // Muat rute awal (Resto -> User)
    _getRoute(widget.restaurantLocation, widget.userLocation);
  }

  Future<void> _initPusher() async {
    try {
      await pusher.init(
        apiKey: '2c68d0ff3232cd32c50f', // Ganti Kunci Pusher Anda
        cluster: 'ap1', // Ganti Cluster Anda
        onConnectionStateChange: onConnectionStateChange,
        onError: onError,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onEvent: onEvent,
      );
      await pusher.subscribe(channelName: 'order-tracking-${widget.orderNumber}');
      await pusher.connect();
    } catch (e) {
      debugPrint("Gagal inisiasi Pusher: $e");
    }
  }

  // --- Callback Pusher ---
  void onConnectionStateChange(dynamic currentState, dynamic previousState) {
    debugPrint("Pusher: $currentState");
    if (mounted) setState(() => statusMessage = "Status Koneksi: $currentState");
  }

  void onError(String message, int? code, dynamic e) {
    debugPrint("Pusher Error: $message code: $code exception: $e");
    if (mounted) setState(() => statusMessage = "Koneksi pelacakan gagal!");
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    debugPrint("Berhasil subscribe ke: $channelName");
    if (mounted) setState(() => statusMessage = "Terhubung ke channel pelacakan...");
  }

  void onEvent(PusherEvent event) {
    debugPrint("Menerima event: ${event.eventName}");
    if (event.eventName == 'status-update') {
      final data = json.decode(event.data);
      if (mounted) setState(() => statusMessage = data['message'] ?? "Status diperbarui");
    }

    if (event.eventName == 'location-update') {
      final data = json.decode(event.data);
      // 💡 4. Buat LatLng latlong2
      final newLocation = latlong.LatLng(
        double.parse(data['lat'].toString()),
        double.parse(data['lng'].toString()),
      );

      if (mounted) {
        setState(() {
          _courierLocation = newLocation;
          statusMessage = "Lokasi kurir diperbarui...";
        });

        // 💡 5. Update rute (Kurir -> User) dan gerakkan kamera
        _getRoute(newLocation, widget.userLocation);
        _mapController.move(newLocation, _mapController.camera.zoom);
      }
    }
  }
  // --- Akhir Callback ---

  Future<void> _getRoute(latlong.LatLng from, latlong.LatLng to) async {
    try {
      // Tipe data sudah sama
      final points = await RouteService.getRoute(from, to);
      if (mounted) setState(() => _routePoints = points);
    } catch (e) {
      debugPrint("Gagal ambil rute: $e");
    }
  }

  @override
  void dispose() {
    pusher.unsubscribe(channelName: 'order-tracking-${widget.orderNumber}');
    // _mapController.dispose(); // MapController tidak perlu dispose
    super.dispose();
  }

  // 💡 6. HELPER UNTUK MEMBUAT MARKER
  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];

    // Marker Restoran
    markers.add(Marker(
      point: widget.restaurantLocation,
      width: 80, height: 80,
      child: const Icon(Icons.store, color: Colors.orange, size: 40),
    ));

    // Marker User
    markers.add(Marker(
      point: widget.userLocation,
      width: 80, height: 80,
      child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
    ));

    // Marker Kurir (💡 GUNAKAN PhotoMarker DENGAN FOTO)
    if (_courierLocation != null) {
      markers.add(PhotoMarker(
        point: _courierLocation!,
        photoUrl: widget.courierPhotoUrl, // Foto Kurir dari parameter
        isDriver: true,
      ));
    }
    return markers;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Melacak Pesanan ${widget.orderNumber}")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                orderNumber: widget.orderNumber,
                currentUserRole: 'customer',
              ),
            ),
          );
        },
        label: const Text('Chat Kurir'),
        icon: const Icon(Icons.chat),
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          Expanded(
            // 💡 7. GANTI WIDGET PETA DENGAN FLUTTERMAP
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _courierLocation ?? widget.restaurantLocation,
                initialZoom: 14.5,
              ),
              children: [
                TileLayer(
  urlTemplate: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png",
  subdomains: const ['a', 'b', 'c', 'd'],
),
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
                  markers: _buildMarkers(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.white,
            child: Text(statusMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}