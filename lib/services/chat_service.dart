// ===== lib/services/chat_service.dart (MODIFIKASI) =====
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:test_application/models/chat_message_model.dart';

class ChatService {
  
  static final String baseUrl = kDebugMode
      ? "http://192.168.1.7/test_application/api" // Sesuaikan IP Anda
      : "https_api_produksi_anda.com";

  // 💡 --- FUNGSI BARU --- 💡
  /// Mengambil daftar chat (order) yang sedang aktif
  static Future<List<dynamic>> getActiveChats(String role, int id) async {
    final uri = Uri.parse("$baseUrl/get_active_chats.php?role=$role&id=$id");
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data;
      } else {
        throw Exception("Gagal memuat daftar chat");
      }
    } catch (e) {
      throw Exception("Error: ${e.toString()}");
    }
  }
  // --- AKHIR FUNGSI BARU ---

  /// Mengambil riwayat chat untuk 1 pesanan
  static Future<List<ChatMessage>> getChatHistory(String orderNumber) async {
    final uri = Uri.parse("$baseUrl/get_chat_history.php?order_number=$orderNumber");
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        throw Exception("Gagal memuat riwayat chat");
      }
    } catch (e) {
      throw Exception("Error: ${e.toString()}");
    }
  }

  /// Mengirim pesan baru
  static Future<bool> sendMessage({
    required String orderNumber,
    required String senderRole,
    required String messageText,
  }) async {
    final uri = Uri.parse("$baseUrl/send_message.php");
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_number': orderNumber,
          'sender_role': senderRole,
          'message_text': messageText,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}