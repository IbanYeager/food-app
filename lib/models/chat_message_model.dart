// ===== lib/models/chat_message_model.dart (FILE BARU) =====
import 'package:intl/intl.dart';

class ChatMessage {
  final String senderRole;
  final String messageText;
  final String timestamp;

  ChatMessage({
    required this.senderRole,
    required this.messageText,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Format waktu
    String formattedDate;
    try {
      final parsedDate = DateTime.tryParse(json['created_at']);
      if (parsedDate != null) {
        formattedDate = DateFormat('HH:mm').format(parsedDate); // Hanya jam & menit
      } else {
        formattedDate = '??:??';
      }
    } catch (e) {
      formattedDate = 'Error';
    }

    return ChatMessage(
      senderRole: json['sender_role'] ?? 'unknown',
      messageText: json['message_text'] ?? '',
      timestamp: formattedDate,
    );
  }
}