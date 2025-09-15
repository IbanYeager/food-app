import 'dart:convert';
import 'package:http/http.dart' as http;

class MenuService {
  static const String baseUrl = "http://192.168.1.6/test_application/api";

  // Fungsi diubah untuk menerima parameter filter
  static Future<Map<String, dynamic>> getMenus({
    int page = 1,
    String? category,
    bool? isPromo,
  }) async {
    const int limit = 10;

    // Membuat map untuk query parameters
    final Map<String, String> queryParameters = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    // Tambahkan parameter filter jika ada nilainya
    if (category != null && category.isNotEmpty) {
      queryParameters['kategori'] = category;
    }
    if (isPromo == true) {
      queryParameters['promo'] = '1';
    }

    // Menggunakan Uri.parse().replace() untuk membangun URL yang aman dan ter-encode
    final uri = Uri.parse("$baseUrl/menus.php").replace(queryParameters: queryParameters);
    
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {"data": [], "total_items": 0}; 
    } else {
      throw Exception("Gagal mengambil data menu");
    }
  }
}