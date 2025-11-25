// ===== lib/services/login_service.dart (MODIFIKASI) =====
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class AuthService {
  static const String baseUrl = "http://192.168.1.7/test_application/api";

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

  // 💡 --- MODIFIKASI FUNGSI REGISTER --- 💡
  static Future<Map<String, dynamic>> register(
    String nama,
    String email, // Email boleh kosong jika mendaftar sebagai kurir
    String password,
    String noHp,
    String role, // 💡 BARU: Tambahkan parameter role
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register.php"),
        body: {
          "nama": nama.trim(),
          "email": email.trim(),
          "password": password,
          "no_hp": noHp.trim(),
          "role": role, // 💡 BARU: Kirim role ke API
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
  // ----------------------------------------

  /// Login user (pakai email atau no_hp)
  static Future<Map<String, dynamic>> login(
    String identifier,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login_unified.php"),
        body: {
          "identifier": identifier.trim(),
          "password": password,
        },
      );

      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          final user = data["data"];
          final String role = data["role"]; 

          final prefs = await SharedPreferences.getInstance();

          int userId = 0;
          try {
            userId = int.parse(user["id"].toString());
          } catch (e) {
            print("Error parsing user id: $e");
          }

          // Simpan data umum
          await prefs.setInt("user_id", userId);
          await prefs.setString("nama", user["nama"] ?? "");
          await prefs.setString("no_hp", user["no_hp"] ?? "");
          await prefs.setString("role", role); 

          // Simpan data spesifik pelanggan
          if (role == "customer") {
            await prefs.setString("email", user["email"] ?? "");
            await prefs.setString("foto", user["foto"] ?? "");
          }

          return {
            "success": true,
            "message": data["message"],
            "role": role,
          };
        } else {
          return {"success": false, "message": data["message"]};
        }
      } else {
        return {"success": false, "message": "Server error (${response.statusCode})"};
      }
    } catch (e) {
      return {"success": false, "message": "Terjadi kesalahan: $e"};
    }
  }


  /// Ambil data user dari SharedPreferences
  static Future<Map<String, dynamic>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "id": prefs.getInt("user_id") ?? 0,
      "nama": prefs.getString("nama") ?? "Pengguna",
      "email": prefs.getString("email") ?? "Belum ada email",
      "no_hp": prefs.getString("no_hp") ?? "Belum ada nomor HP",
      "foto": prefs.getString("foto") ?? "",
      "role": prefs.getString("role") ?? "customer", 
    };
  }

  /// Logout (hapus data user)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // 💡 PERBAIKAN: Jangan clear(), tapi hapus satu per satu
    await prefs.remove('user_id');
    await prefs.remove('nama');
    await prefs.remove('email');
    await prefs.remove('no_hp');
    await prefs.remove('foto');
    await prefs.remove('role');
  }
}