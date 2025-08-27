import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://192.168.1.9/TEST_APPLICATION/api";

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login.php"), // ⬅️ ini baru benar
        body: {
          "email": email.trim(),
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "success": data["success"],
          "message": data["message"],
          "user": data["user"] ?? {},
        };
      } else {
        return {
          "success": false,
          "message": "Server error (${response.statusCode})",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Terjadi kesalahan: $e",
      };
    }
  }
}

