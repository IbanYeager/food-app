// menu_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MenuService {
  static final String baseUrl = kDebugMode
      ? "http://192.168.1.7/test_application/api"
      : "https://api.production-url-anda.com";

  static Future<Map<String, dynamic>> getMenus({
    int page = 1,
    int limit = 10,
    String? category,
    // Parameter ini digunakan HomeScreen untuk mengambil "Menu Rekomendasi" (sebagai pengganti filter popularitas)
    bool? isPromo, 
  }) async {
    final Map<String, String> queryParameters = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (category != null && category.isNotEmpty) {
      queryParameters['kategori'] = category;
    }
    if (isPromo == true) {
      queryParameters['promo'] = '1';
    }

    final uri = Uri.parse("$baseUrl/menus.php").replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Koneksi timeout. Periksa koneksi internet Anda.');
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return {"data": [], "total_items": 0};
      } else {
        throw Exception("Gagal mengambil data menu. Status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Terjadi kesalahan: ${e.toString()}");
    }
  }
}