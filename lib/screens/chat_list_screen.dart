// ===== lib/screens/chat_list_screen.dart (FILE BARU) =====
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_application/services/chat_service.dart';
import 'package:test_application/screens/chat_screen.dart';
import 'package:latlong2/latlong.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<dynamic>> _chatsFuture;
  String _currentUserRole = '';

  @override
  void initState() {
    super.initState();
    _chatsFuture = _fetchActiveChats();
  }

  Future<List<dynamic>> _fetchActiveChats() async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('user_id') ?? 0;
    final String role = prefs.getString('role') ?? 'customer';
    
    setState(() {
      _currentUserRole = role; // Simpan role untuk navigasi
    });

    if (userId == 0) {
      throw Exception("User ID tidak ditemukan");
    }
    
    return ChatService.getActiveChats(role, userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pesan Aktif'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _chatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat chat: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada pesan aktif.\nChat hanya tersedia saat pesanan diantar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final chats = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () {
              setState(() {
                _chatsFuture = _fetchActiveChats();
              });
              return _chatsFuture;
            },
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final orderNumber = chat['order_number'];
                final otherPartyName = chat['other_party_name'];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _currentUserRole == 'customer' 
                          ? Colors.blueAccent 
                          : Colors.green,
                      child: Icon(
                        _currentUserRole == 'customer' 
                            ? Icons.delivery_dining 
                            : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      _currentUserRole == 'customer' 
                          ? "Kurir: $otherPartyName"
                          : "Customer: $otherPartyName",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Order: #$orderNumber"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            orderNumber: orderNumber,
                            currentUserRole: _currentUserRole,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}