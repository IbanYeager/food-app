import 'package:shared_preferences/shared_preferences.dart';

class SessionHelper {
  static Future<void> saveUser(String id, String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('id', id);
    await prefs.setString('name', name);
    await prefs.setString('email', email);
  }

  static Future<Map<String, String?>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "id": prefs.getString('id'),
      "name": prefs.getString('name'),
      "email": prefs.getString('email'),
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
