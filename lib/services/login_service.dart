import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://192.168.1.6/TEST_APPLICATION/api";

  /// Fungsi untuk sensor email
  static String maskEmail(String email) {
    if (!email.contains("@")) return email;

    final parts = email.split("@");
    final name = parts[0];
    final domain = parts[1];

    if (name.length <= 3) {
      return "${name[0]}***@$domain";
    } else {
      return "${name.substring(0, 3)}*****@$domain";
    }
  }

  /// Register user baru
  static Future<Map<String, dynamic>> register(
    String nama,
    String email,
    String password,
    String noHp, // ✅ tambahan nomor HP
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register.php"),
        body: {
          "nama": nama.trim(),
          "email": email.trim(),
          "password": password,
          "no_hp": noHp.trim(), // ✅ kirim no_hp
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          "success": data["success"] == true,
          "message": data["message"],
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

  /// Login user
  /// Login user (pakai email atau no_hp)
static Future<Map<String, dynamic>> login(
  String identifier,
  String password,
) async {
  try {
    final response = await http.post(
      Uri.parse("$baseUrl/login.php"),
      body: {
        "email": identifier.trim(), // kirim ke PHP (bisa email/no_hp)
        "password": password,
      },
    );

    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        final user = data["data"];

        // Simpan data user ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();

        int userId = 0;
        if (user["id"] != null) {
          try {
            userId = int.parse(user["id"].toString());
          } catch (e) {
            print("Error parsing user id: $e");
          }
        }

        await prefs.setInt("user_id", userId);
        await prefs.setString("nama", user["nama"] ?? "");
        await prefs.setString("email", user["email"] ?? "");
        await prefs.setString("no_hp", user["no_hp"] ?? "");
        await prefs.setString("foto", user["foto"] ?? "");

        return {
          "success": true,
          "message": data["message"],
        };
      } else {
        return {
          "success": false,
          "message": data["message"],
        };
      }
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


  /// Ambil data user dari SharedPreferences
  static Future<Map<String, dynamic>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "id": prefs.getInt("user_id") ?? 0,
      "nama": prefs.getString("nama") ?? "Pengguna",
      "email": prefs.getString("email") ?? "Belum ada email",
      "no_hp": prefs.getString("no_hp") ?? "Belum ada nomor HP", // ✅ tampilkan no_hp
      "foto": prefs.getString("foto") ?? "",                     // ✅ tampilkan foto
    };
  }

  /// Logout (hapus data user)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
