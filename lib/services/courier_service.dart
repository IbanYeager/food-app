import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CourierService {
  
  // 💡 Pastikan IP ini sesuai dengan laptop Anda (sama dengan file PHP)
  static final String baseUrl = kDebugMode
      ? "http://192.168.1.7/test_application/api" 
      : "https://api.production-url-anda.com";

  /// Mengambil pesanan yang SUDAH DITUGASKAN ke kurir ini (Status: Diantar)
  static Future<List<dynamic>> getAssignedTasks(int courierId) async {
    final uri = Uri.parse("$baseUrl/get_courier_tasks.php?courier_id=$courierId");

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data;
        } else {
          return [];
        }
      } else {
        throw Exception("Gagal memuat tugas: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Terjadi kesalahan: ${e.toString()}");
    }
  }

  /// Mengambil riwayat pesanan kurir
  static Future<List<dynamic>> getCourierHistory(int courierId) async {
    final uri = Uri.parse("$baseUrl/get_courier_history.php?courier_id=$courierId");

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is List ? data : [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}