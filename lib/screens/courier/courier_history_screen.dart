// ===== lib/screens/courier/courier_history_screen.dart (PERBAIKAN REFRESH) =====
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:test_application/services/courier_service.dart';
import 'package:test_application/services/order_service.dart';

class CourierHistoryScreen extends StatefulWidget {
  const CourierHistoryScreen({super.key});

  @override
  State<CourierHistoryScreen> createState() => _CourierHistoryScreenState();
}

class _CourierHistoryScreenState extends State<CourierHistoryScreen> {
  // Gunakan variabel List, bukan Future, agar mudah di-refresh
  List<dynamic> _historyList = [];
  bool _isLoading = true;
  
  final NumberFormat formatRupiah =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadHistory(); // Muat data saat pertama kali dibuka
  }

  // Fungsi untuk memuat data
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final int courierId = prefs.getInt('user_id') ?? 0;
      
      // Panggil Service
      final data = await CourierService.getCourierHistory(courierId);
      
      if (mounted) {
        setState(() {
          _historyList = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteOrder(String orderNumber) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text('Hapus riwayat pengantaran ini?'),
        actions: [
          TextButton(child: const Text('Batal'), onPressed: () => Navigator.pop(ctx, false)),
          TextButton(child: const Text('Hapus', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    final result = await OrderService.deleteOrder(orderNumber);
    
    if (result['success'] == true) {
      // Refresh otomatis setelah menghapus
      _loadHistory(); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Riwayat berhasil dihapus"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus: ${result['message']}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Pengantaran"),
        // Tambahkan tombol refresh manual di pojok kanan atas
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          )
        ],
      ),
      // 💡 RefreshIndicator: Tarik ke bawah untuk refresh
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _historyList.isEmpty
                ? ListView( // Gunakan ListView agar bisa ditarik (refresh) meski kosong
                    children: const [
                      SizedBox(height: 200),
                      Center(child: Text("Belum ada riwayat pengantaran selesai.")),
                    ],
                  )
                : ListView.builder(
                    itemCount: _historyList.length,
                    itemBuilder: (context, index) {
                      final order = _historyList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: Text("Order #${order['order_number']}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Customer: ${order['nama_user']}"),
                              Text(formatRupiah.format(double.parse(order['total'].toString()))),
                              const SizedBox(height: 4),
                              Text(
                                "Status: ${order['status']}",
                                style: TextStyle(
                                  color: order['status'] == 'Dibatalkan' ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              Text(
                                "Tanggal: ${order['waktu']}",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteOrder(order['order_number']),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}