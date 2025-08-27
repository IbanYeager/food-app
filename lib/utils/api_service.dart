import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(AppConstants.apiLogin),
      body: {"email": email, "password": password},
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse(AppConstants.apiRegister),
      body: {"name": name, "email": email, "password": password},
    );
    return json.decode(response.body);
  }
}
