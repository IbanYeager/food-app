// ===== lib/screens/courier/courier_dashboard_screen.dart (AUTO REFRESH) =====
import 'dart:convert'; // Tambahkan ini
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart'; // Import Pusher
import 'package:test_application/services/courier_service.dart';
import 'courier_active_delivery_screen.dart';

class CourierDashboardScreen extends StatefulWidget {
  const CourierDashboardScreen({super.key});

  @override
  State<CourierDashboardScreen> createState() => _CourierDashboardScreenState();
}

class _CourierDashboardScreenState extends State<CourierDashboardScreen> {
  // Instance Pusher
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  
  List<dynamic> _activeTasks = [];
  bool _isLoading = true;
  String? _courierName;
  int _courierId = 0; // Simpan ID

  @override
  void initState() {
    super.initState();
    _fetchCourierTasks(); // Load data awal
    // Pusher akan di-init setelah kita dapat ID kurir di dalam _fetchCourierTasks
  }

  @override
  void dispose() {
    // Putus koneksi saat keluar halaman agar hemat baterai
    pusher.unsubscribe(channelName: 'courier-$_courierId');
    super.dispose();
  }

  // 💡 Fungsi Init Pusher
  Future<void> _initPusher(int courierId) async {
    try {
      await pusher.init(
        apiKey: '2c68d0ff3232cd32c50f', // Ganti dengan Key Anda
        cluster: 'ap1',                 // Ganti dengan Cluster Anda
        onEvent: (PusherEvent event) {
          print("Event diterima: ${event.eventName}");
          
          // Jika ada event 'new-job', refresh otomatis!
          if (event.eventName == 'new-job') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🔔 Tugas Baru Masuk!"),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
              // Panggil fungsi refresh
              _fetchCourierTasks(isRefresh: true); 
            }
          }
        },
      );

      // Subscribe ke channel pribadi kurir
      await pusher.subscribe(channelName: 'courier-$courierId');
      await pusher.connect();
      print("Berhasil subscribe ke courier-$courierId");

    } catch (e) {
      print("Error Pusher: $e");
    }
  }

  Future<void> _fetchCourierTasks({bool isRefresh = false}) async {
    if (!isRefresh) setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final int courierId = prefs.getInt('user_id') ?? 0;
      final String name = prefs.getString('nama') ?? 'Kurir';

      if (mounted) {
        setState(() {
          _courierName = name;
          _courierId = courierId;
        });
      }

      if (courierId == 0) {
         setState(() => _isLoading = false);
         return;
      }

      // 💡 Init Pusher hanya sekali (saat pertama load)
      if (!isRefresh) {
        _initPusher(courierId);
      }

      final tasks = await CourierService.getAssignedTasks(courierId);
      
      if (mounted) {
        setState(() {
          _activeTasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, ${_courierName ?? "Kurir"}!'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchCourierTasks(isRefresh: true),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _activeTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.motorcycle, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          "Belum ada tugas pengantaran.",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _activeTasks.length,
                    itemBuilder: (context, index) {
                      final task = _activeTasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepOrange[100],
                            child: const Icon(Icons.delivery_dining, color: Colors.deepOrange),
                          ),
                          title: Text(
                            "Antar Order #${task['order_number']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("Pelanggan: ${task['nama_user']}"),
                              Text("Total: Rp ${double.parse(task['total'].toString()).toStringAsFixed(0)}"),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: const Text("TUGAS BARU - SEGERA ANTAR", 
                                  style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)
                                ),
                              )
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourierActiveDeliveryScreen(
                                  order: task,
                                ),
                              ),
                            ).then((_) => _fetchCourierTasks(isRefresh: true));
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}