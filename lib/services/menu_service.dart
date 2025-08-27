import 'dart:convert';
import 'package:http/http.dart' as http;

class MenuService {
  static const String baseUrl = "http://192.168.1.9/test_application/api";

  static Future<Map<String, dynamic>> getMenus(int page, {int limit = 10}) async {
    final response = await http.get(Uri.parse("$baseUrl/menus.php?page=$page&limit=$limit"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal mengambil data menu");
    }
  }
}
