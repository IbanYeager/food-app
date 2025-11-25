import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:test_application/services/route_service.dart';
import 'package:test_application/screens/chat_screen.dart';
import 'package:test_application/widgets/photo_marker.dart';

class OrderTrackingScreen extends StatefulWidget {
  final latlong.LatLng userLocation;       // Lokasi User
  final latlong.LatLng restaurantLocation; // Lokasi Toko
  final String orderNumber;
  final String? courierPhotoUrl; 

  const OrderTrackingScreen({
    super.key,
    required this.orderNumber,
    required this.userLocation,
    required this.restaurantLocation,
    this.courierPhotoUrl, 
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  final MapController _mapController = MapController();
  
  latlong.LatLng? _courierLocation; 
  List<latlong.LatLng> _routePoints = [];
  String statusMessage = "Menghubungkan ke server pelacakan...";

  @override
  void initState() {
    super.initState();
    // Awalnya, posisi kurir diasumsikan di Toko
    _courierLocation = widget.restaurantLocation;
    
    _initPusher();
    
    // Ambil rute statis: Toko -> User
    _getRoute(widget.restaurantLocation, widget.userLocation);
  }

  Future<void> _initPusher() async {
    try {
      await pusher.init(
        apiKey: '2c68d0ff3232cd32c50f', // Pastikan Key Benar
        cluster: 'ap1', 
        onEvent: onEvent,
      );
      await pusher.subscribe(channelName: 'order-tracking-${widget.orderNumber}');
      await pusher.connect();
    } catch (e) {
      debugPrint("Gagal inisiasi Pusher: $e");
    }
  }

  void onEvent(PusherEvent event) {
    // 1. Update Status Teks
    if (event.eventName == 'status-update') {
      final data = json.decode(event.data);
      if (mounted) setState(() => statusMessage = data['message'] ?? "Status diperbarui");
    }

    // 2. Update Lokasi Kurir Realtime
    if (event.eventName == 'location-update') {
      final data = json.decode(event.data);
      final newLocation = latlong.LatLng(
        double.parse(data['lat'].toString()),
        double.parse(data['lng'].toString()),
      );

      if (mounted) {
        setState(() {
          _courierLocation = newLocation;
          statusMessage = "Kurir sedang bergerak...";
        });
        // Opsi: User tidak perlu re-route setiap detik, cukup gerakkan marker
        // Tapi jika ingin akurat sisa jarak, bisa panggil _getRoute lagi
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
        
        if (points.isNotEmpty) {
           _fitCamera(points);
        }
      }
    } catch (e) {
      debugPrint("Gagal ambil rute: $e");
    }
  }

  void _fitCamera(List<latlong.LatLng> points) {
    try {
        if (points.isEmpty) return;

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
        
        // Perbaikan LatLngBounds
        final bounds = LatLngBounds(
            latlong.LatLng(minLat, minLng),
            latlong.LatLng(maxLat, maxLng),
        );

        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ),
        );
    } catch(e) {
        debugPrint("Error fit camera: $e");
    }
  }

  @override
  void dispose() {
    pusher.unsubscribe(channelName: 'order-tracking-${widget.orderNumber}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pesanan #${widget.orderNumber}")),
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
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.restaurantLocation, // Awal di Toko
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
                      point: widget.restaurantLocation,
                      width: 60, height: 60,
                      child: const Icon(Icons.store, color: Colors.orange, size: 40),
                    ),
                    // Marker User (Tujuan)
                    Marker(
                      point: widget.userLocation,
                      width: 60, height: 60,
                      child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 40),
                    ),
                    // Marker Kurir (Bergerak)
                    if (_courierLocation != null)
                      PhotoMarker(
                        point: _courierLocation!,
                        photoUrl: widget.courierPhotoUrl,
                        isDriver: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.white,
            child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Status Pengantaran", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(statusMessage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                )
            ),
          )
        ],
      ),
    );
  }
}