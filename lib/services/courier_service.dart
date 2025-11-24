// ===== lib/services/courier_service.dart (MODIFIKASI) =====
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CourierService {
  
  static final String baseUrl = kDebugMode
      ? "http://192.168.1.6/test_application/api" // Sesuaikan IP Anda
      : "https://api.production-url-anda.com";

  // 💡 GANTI FUNGSI LAMA ATAU TAMBAHKAN FUNGSI INI
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
  static Future<List<dynamic>> getCourierHistory(int courierId) async {
    final uri = Uri.parse("$baseUrl/get_courier_history.php?courier_id=$courierId");

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}