import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class DeliveryService {
  Timer? _locationTimer;
  bool _isDelivering = false;

  // 💡 IP Address (Pastikan sama dengan file PHP config Anda)
  static const String _baseUrl = "http://192.168.1.7/test_application/api";

  final String _statusApiUrl = "$_baseUrl/update_delivery_status.php";
  final String _locationApiUrl = "$_baseUrl/update_courier_location.php";
  final String _finishApiUrl = "$_baseUrl/update_order_status.php";

  bool get isDelivering => _isDelivering;

  // --- 1. Memulai Pengantaran ---
  Future<Map<String, dynamic>> startDelivery(String orderNumber, int courierId) async {
    if (_isDelivering) {
      return {'success': false, 'message': 'Sudah ada pengantaran aktif'};
    }

    try {
      // Update status di database menjadi 'Diantar'
      final response = await http.post(
        Uri.parse(_statusApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_number': orderNumber,
          'courier_id': courierId,
          'status': 'Diantar',
        }),
      );
      
      final data = json.decode(response.body);
      if (data['success'] != true) {
        return {'success': false, 'message': 'Gagal memulai: ${data['message']}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error koneksi: $e'};
    }

    // Mulai timer kirim lokasi (setiap 10 detik)
    _isDelivering = true;
    _sendCurrentLocation(orderNumber, courierId); // Kirim langsung pertama kali
    
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isDelivering) {
        _sendCurrentLocation(orderNumber, courierId);
      } else {
        timer.cancel();
      }
    });
    
    return {'success': true, 'message': 'Pengantaran dimulai'};
  }

  // --- 2. Mengirim Lokasi Real-time ---
  Future<void> _sendCurrentLocation(String orderNumber, int courierId) async {
    if (!_isDelivering) return;

    try {
      // Cek izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          // Jangan request permission di dalam loop timer background, bisa mengganggu UI
          debugPrint("Izin lokasi ditolak");
          return;
      }
      
      // Ambil posisi GPS
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Kirim ke API
      await http.post(
        Uri.parse(_locationApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_number': orderNumber,
          'courier_id': courierId,
          'lat': position.latitude,
          'lng': position.longitude,
        }),
      );
      
      debugPrint("Lokasi terkirim: ${position.latitude}, ${position.longitude}");
      
    } catch (e) {
      debugPrint("Gagal mengirim lokasi: $e");
    }
  }

  // --- 3. Menyelesaikan Pengantaran (API) ---
  Future<bool> finishDelivery(String orderNumber) async {
    try {
      final response = await http.post(
        Uri.parse(_finishApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_number': orderNumber,
          'status': 'Selesai' 
        }),
      );

      debugPrint("Finish Response: ${response.body}");

      final data = json.decode(response.body);
      if (data['success'] == true) {
        stopDelivery(); // Matikan timer lokal
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Gagal menyelesaikan pesanan: $e");
      return false;
    }
  }

  // --- 4. Hentikan Timer Lokal ---
  void stopDelivery() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isDelivering = false;
    debugPrint("Pengantaran dihentikan (Timer mati)");
  }
}