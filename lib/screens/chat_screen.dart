// ===== lib/screens/chat_screen.dart (PERBAIKAN) =====
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:test_application/models/chat_message_model.dart';
import 'package:test_application/services/chat_service.dart';
import 'package:intl/intl.dart'; // 💡 <--- INI PERBAIKANNYA

class ChatScreen extends StatefulWidget {
  final String orderNumber;
  final String currentUserRole; // 'customer' atau 'courier'

  const ChatScreen({
    super.key,
    required this.orderNumber,
    required this.currentUserRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistoryAndInitPusher();
  }

  Future<void> _loadHistoryAndInitPusher() async {
    // 1. Muat riwayat chat
    try {
      final history = await ChatService.getChatHistory(widget.orderNumber);
      setState(() {
        _messages = history;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat riwayat chat: $e')),
      );
    }
    
    // 2. Inisialisasi Pusher
    try {
      await pusher.init(
        apiKey: '2c68d0ff3232cd32c50f', // Ganti Kunci Pusher
        cluster: 'ap1', // Ganti Cluster
        onEvent: onPusherEvent, // Set listener
      );
      await pusher.subscribe(channelName: 'order-tracking-${widget.orderNumber}');
      await pusher.connect();
    } catch (e) {
      debugPrint("Gagal konek Pusher: $e");
    }
  }

  void onPusherEvent(PusherEvent event) {
    // 3. Dengarkan event 'new-message'
    if (event.eventName == 'new-message') {
      final data = json.decode(event.data);
      final newMessage = ChatMessage.fromJson(data);

      // Cek agar tidak duplikat (jika pengirim adalah kita)
      if (newMessage.senderRole == widget.currentUserRole) {
         // Kita tidak perlu menambahkan pesan kita sendiri DARI PUSHER,
         // karena kita sudah menambahkannya secara optimis di _sendMessage
         return;
      }

      if (mounted) {
        setState(() {
          _messages.add(newMessage);
        });
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    pusher.unsubscribe(channelName: 'order-tracking-${widget.orderNumber}');
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    
    // Optimistic UI: Tampilkan pesan di layar sebelum dikirim
    final optimisticMessage = ChatMessage(
      senderRole: widget.currentUserRole,
      messageText: text,
      timestamp: DateFormat('HH:mm').format(DateTime.now()),
    );
    
    setState(() {
      _messages.add(optimisticMessage);
    });
    _scrollToBottom();

    // Kirim ke server
    final bool success = await ChatService.sendMessage(
      orderNumber: widget.orderNumber,
      senderRole: widget.currentUserRole,
      messageText: text,
    );
    
    if (!success) {
      // Jika gagal, tampilkan error (Anda bisa menambahkan logic retry)
      setState(() {
         _messages.remove(optimisticMessage); // Hapus pesan optimis
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim pesan.')),
      );
    }
    // Jika sukses, tidak perlu lakukan apa-apa,
    // karena penerima akan mendapatkannya dari Pusher.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Pengantaran')),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderRole == widget.currentUserRole;
                      return _buildChatBubble(msg, isMe);
                    },
                  ),
          ),
          _buildTextInput(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isMe ? Colors.deepOrange[400] : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.messageText,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              msg.timestamp,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: "Ketik pesan...",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.deepOrange),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}