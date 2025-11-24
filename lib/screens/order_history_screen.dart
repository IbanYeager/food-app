import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
// 💡 Import untuk tipe data lokasi peta gratis
import 'package:latlong2/latlong.dart' as latlong;

import '../services/order_service.dart';
import '../models/order_model.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<Order>> _ordersFuture;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<Order>> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('user_id');

    if (userId != null && userId != 0) {
      return OrderService.fetchOrders(userId.toString());
    } else {
      throw Exception("User ID tidak ditemukan. Harap login kembali.");
    }
  }

  Future<void> _refreshOrders() async {
    if (mounted) {
      setState(() {
        _ordersFuture = _loadOrders();
      });
    }
  }

  // --- Logika Hapus Riwayat ---
  Future<void> _showDeleteConfirmationDialog(String orderNumber) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Riwayat'),
          content: const Text(
              'Apakah Anda yakin ingin menghapus riwayat pesanan ini secara permanen?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                _deleteOrder(orderNumber); // Panggil fungsi hapus
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteOrder(String orderNumber) async {
    if (!mounted) return;
    setState(() {
      _isDeleting = true;
    });

    final result = await OrderService.deleteOrder(orderNumber);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Riwayat berhasil dihapus'),
            backgroundColor: Colors.green),
      );
      _refreshOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus: ${result['message']}')),
      );
    }

    setState(() {
      _isDeleting = false;
    });
  }

  // --- Helper UI Status ---
  Widget _getIconForStatus(String status) {
    switch (status) {
      case 'Dikonfirmasi':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'Dibatalkan':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'Pending':
        return const Icon(Icons.hourglass_top, color: Colors.orange);
      case 'Diantar':
        return const Icon(Icons.delivery_dining, color: Colors.blue);
      case 'Selesai':
        return const Icon(Icons.task_alt, color: Colors.green);
      default:
        return const Icon(Icons.receipt_long, color: Colors.deepOrange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Pesanan"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        color: Colors.deepOrange,
        child: Stack(
          children: [
            FutureBuilder<List<Order>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.deepOrange));
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Gagal memuat riwayat: ${snapshot.error}",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 80, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text("Belum ada riwayat pesanan"),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _refreshOrders,
                          child: const Text("Coba Muat Ulang"),
                        ),
                      ],
                    ),
                  );
                }

                final orders = snapshot.data!;
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final formatRupiah = NumberFormat.currency(
                        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

                    final bool isFinished =
                        order.status == 'Selesai' || order.status == 'Dibatalkan';
                    final bool isDelivering = order.status == 'Diantar';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: _getIconForStatus(order.status),
                        title: Text(
                          "Order #${order.orderNumber}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Status: ${order.status}"),
                            Text("Tanggal: ${order.date}"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatRupiah.format(order.total),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                  fontSize: 14),
                            ),
                            
                            // Tombol Hapus (Muncul jika Selesai/Batal)
                            if (isFinished)
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: _isDeleting
                                    ? null
                                    : () => _showDeleteConfirmationDialog(
                                        order.orderNumber),
                              ),

                            // Tombol Lacak (Muncul jika Diantar)
                            if (isDelivering)
                              IconButton(
                                icon: const Icon(Icons.track_changes,
                                    color: Colors.blueAccent),
                                onPressed: () {
                                  // 💡 Navigasi ke Peta (Flutter Map)
                                  // Konversi data ke latlong.LatLng
                                  final latlong.LatLng userLoc = latlong.LatLng(
                                      order.destinationLat,
                                      order.destinationLng);
                                  final latlong.LatLng restoLoc = latlong.LatLng(
                                      order.originLat, order.originLng);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderTrackingScreen(
                                        orderNumber: order.orderNumber,
                                        userLocation: userLoc,
                                        restaurantLocation: restoLoc,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        onTap: () {
                          // Opsional: Bisa navigasi ke detail pesanan jika ada
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Detail Pesanan #${order.orderNumber}")),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
            // Loading overlay saat menghapus
            if (_isDeleting)
              Container(
                color: Colors.black.withOpacity(0.1),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                ),
              ),
          ],
        ),
      ),
    );
  }
}