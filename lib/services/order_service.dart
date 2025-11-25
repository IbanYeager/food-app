// ===== lib/services/order_service.dart (MODIFIKASI) =====
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import 'package:test_application/models/cart_item.dart';
import 'package:latlong2/latlong.dart'; // 💡 1. IMPORT LatLng

class OrderService {
  static const String baseUrl = "http://192.168.1.7/test_application/api";

  // Fungsi fetchOrders (ANDA SUDAH PUNYA INI)
  static Future<List<Order>> fetchOrders(String userId) async {
    final response =
        await http.get(Uri.parse("$baseUrl/orders.php?user_id=$userId"));

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty && response.body.trim() != '[]') {
        List data = json.decode(response.body);
        // 💡 Model Order.fromJson yang baru akan otomatis mem-parse data lokasi
        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        return [];
      }
    } else {
      throw Exception(
          "Gagal mengambil data pesanan. Status Code: ${response.statusCode}");
    }
  }

  // 💡 2. MODIFIKASI 'createOrder'
  static Future<Map<String, dynamic>> createOrder({
    required String userId,
    required double total,
    required List<CartItem> items,
    required LatLng userLocation, // 💡 3. TAMBAHKAN parameter ini
  }) async {
    
    List<Map<String, dynamic>> itemsAsMap = items.map((item) {
      return {
        'id': item.id,
        'nama': item.nama,
        'harga': item.harga,
        'quantity': item.quantity,
      };
    }).toList();

    String body = json.encode({
      'user_id': userId,
      'total': total,
      'items': itemsAsMap,
      'user_lat': userLocation.latitude,  // 💡 4. KIRIM lat
      'user_lng': userLocation.longitude, // 💡 5. KIRIM lng
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/buat_pesanan.php"),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server Error: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // 💡 Fungsi deleteOrder (ANDA SUDAH PUNYA INI)
  static Future<Map<String, dynamic>> deleteOrder(String orderNumber) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/delete_order.php"),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'order_number': orderNumber
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
         return {
          'success': false,
          'message': 'Server Error: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }
}