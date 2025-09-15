import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_application/screens/edit_profile_screen.dart';
import 'package:test_application/screens/login_screen.dart';
import 'package:test_application/screens/setting_screen.dart';
import 'package:test_application/services/cart_service.dart'; // 1. Import CartService

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String nama = "";
  String email = "";
  String? foto;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedUser();
  }

  // ... (Fungsi _loadCachedUser, fetchUser, dan maskEmail tidak berubah)
  Future<void> _loadCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nama = prefs.getString('nama') ?? "";
      email = prefs.getString('email') ?? "";
      foto = prefs.getString('foto');
      loading = false;
    });
    fetchUser();
  }

  Future<void> fetchUser() async {
    final prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('user_id') ?? 0;
    if (userId == 0) return;
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.9/test_application/api/get_user.php?id=$userId'),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final newNama = data['data']['nama'] ?? "";
          final newEmail = data['data']['email'] ?? "";
          final newFoto = data['data']['foto'];
          await prefs.setString('nama', newNama);
          await prefs.setString('email', newEmail);
          if (newFoto != null) {
            await prefs.setString('foto', newFoto);
          }
          if (mounted) {
            setState(() {
              nama = newNama;
              email = newEmail;
              foto = newFoto;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Gagal fetch user: $e");
    }
  }

  String maskEmail(String email) {
    if (email.isEmpty || !email.contains("@")) return email;
    final parts = email.split("@");
    final username = parts[0];
    final domain = parts[1];
    final visible = username.length > 2 ? username.substring(0, 2) : username[0];
    return "$visible***@$domain";
  }

  // 2. Buat fungsi untuk menampilkan dialog konfirmasi
  Future<void> _showLogoutConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
            ),
            TextButton(
              child: const Text('Keluar', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                _performLogout(); // Lakukan proses logout
              },
            ),
          ],
        );
      },
    );
  }

  // 3. Buat fungsi terpisah untuk proses logout
  Future<void> _performLogout() async {
    // Kosongkan keranjang belanja
    CartService().clearCart();

    // Hapus data sesi pengguna secara spesifik
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('nama');
    await prefs.remove('email');
    await prefs.remove('foto');

    if (!mounted) return;

    // Arahkan ke LoginScreen dan hapus semua riwayat halaman
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchUser, // Tambahkan pull-to-refresh
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: (foto != null && foto!.isNotEmpty)
                          ? NetworkImage(foto!)
                          : const AssetImage("assets/images/profile.png")
                              as ImageProvider,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      nama.isNotEmpty ? nama : "Pengguna",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email.isNotEmpty ? maskEmail(email) : "Belum ada email",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24), // Beri jarak lebih

                    // === Kumpulan Menu Aksi ===
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: const Text("Edit Profil"),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              );
                              if (updated == true) {
                                _loadCachedUser();
                              }
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.settings_outlined),
                            title: const Text("Pengaturan"),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.logout, color: Colors.red),
                            title: const Text("Keluar", style: TextStyle(color: Colors.red)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                            onTap: () {
                              // 4. Panggil dialog konfirmasi, bukan langsung logout
                              _showLogoutConfirmationDialog();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}