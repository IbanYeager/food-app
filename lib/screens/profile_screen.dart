// ===== lib/screens/profile_screen.dart (FINAL & RAPI) =====
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import screen dan provider yang dibutuhkan
import 'package:test_application/providers/cart_provider.dart';
import 'package:test_application/screens/edit_profile_screen.dart';
import 'package:test_application/screens/login_screen.dart';
import 'package:test_application/screens/setting_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Variabel State
  String nama = "";
  String email = "";
  String noHp = "";
  String? foto;
  String role = "customer"; // Default role
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedUser();
  }

  // 1. Muat data dari SharedPreferences (Data Lokal)
  Future<void> _loadCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nama = prefs.getString('nama') ?? "Pengguna";
      role = prefs.getString('role') ?? "customer";
      foto = prefs.getString('foto'); // Foto bisa null

      // Ambil data spesifik berdasarkan role
      if (role == "customer") {
        email = prefs.getString('email') ?? "";
      } else {
        noHp = prefs.getString('no_hp') ?? "";
      }
      loading = false;
    });

    // Jika customer, coba ambil data terbaru dari API
    if (role == "customer") {
      _fetchUserData();
    }
  }

  // 2. Ambil data terbaru dari Server (Opsional/Khusus Customer)
  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('user_id') ?? 0;
    String userRole = prefs.getString('role') ?? 'customer'; // 💡 Ambil Role

    if (userId == 0) return;

    try {
      // 💡 TAMBAHKAN PARAMETER &role=$userRole KE URL
      final response = await http.get(
        Uri.parse('http://192.168.1.6/test_application/api/get_user.php?id=$userId&role=$userRole'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final newData = data['data'];
          
          // Simpan ke lokal
          await prefs.setString('nama', newData['nama'] ?? "");
          
          // Simpan data sesuai role
          if (userRole == 'customer') {
             await prefs.setString('email', newData['email'] ?? "");
          } else {
             await prefs.setString('no_hp', newData['no_hp'] ?? "");
          }

          // 💡 SIMPAN FOTO (PENTING)
          if (newData['foto'] != null) {
            await prefs.setString('foto', newData['foto']);
          }

          // Update UI
          if (mounted) {
            setState(() {
              nama = newData['nama'] ?? "";
              if (userRole == 'customer') email = newData['email'] ?? "";
              if (userRole == 'courier') noHp = newData['no_hp'] ?? "";
              foto = newData['foto'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Gagal update data user: $e");
    }
  }

  // 3. Helper Sensor Email
  String _maskEmail(String email) {
    if (email.isEmpty || !email.contains("@")) return email;
    final parts = email.split("@");
    if (parts[0].length > 2) {
      return "${parts[0].substring(0, 2)}***@${parts[1]}";
    }
    return email;
  }

  // 4. Dialog Konfirmasi Logout
  Future<void> _showLogoutDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(ctx);
              _performLogout();
            },
          ),
        ],
      ),
    );
  }

  // 5. Proses Logout
  Future<void> _performLogout() async {
    // Reset Cart jika customer
    if (role == "customer" && mounted) {
      context.read<CartProvider>().clearCart();
    }

    // Hapus Data SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus semua data login

    if (!mounted) return;

    // Kembali ke Login Screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Saya"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              // Jika customer refresh ke API, jika kurir refresh cache lokal
              onRefresh: role == "customer" ? _fetchUserData : _loadCachedUser,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // --- BAGIAN FOTO PROFIL ---
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade200, width: 4),
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: (foto != null && foto!.isNotEmpty)
                                  ? NetworkImage(foto!)
                                  : const AssetImage("assets/images/profil.png") as ImageProvider,
                              child: (foto == null || foto!.isEmpty)
                                  ? Icon(
                                      role == 'courier' ? Icons.delivery_dining : Icons.person,
                                      size: 50,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- NAMA USER ---
                    Text(
                      nama,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),

                    // --- EMAIL (Customer) / NO HP (Kurir) ---
                    Text(
                      role == "customer"
                          ? (email.isNotEmpty ? _maskEmail(email) : "Email tidak tersedia")
                          : (noHp.isNotEmpty ? noHp : "No. HP tidak tersedia"),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 5),
                    
                    // Badge Role
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: role == 'courier' ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role == 'courier' ? "Mitra Kurir" : "Pelanggan",
                        style: TextStyle(
                          color: role == 'courier' ? Colors.green[800] : Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- MENU OPTIONS ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 1. EDIT PROFIL (Untuk Semua Role)
                          _buildMenuItem(
                            icon: Icons.edit_outlined,
                            text: "Edit Profil",
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProfileScreen(role: role),
                                ),
                              );
                              // Jika berhasil edit, refresh data
                              if (result == true) {
                                _loadCachedUser();
                              }
                            },
                          ),
                          
                          const Divider(height: 1, indent: 20, endIndent: 20),

                          // 2. PENGATURAN (Hanya Customer - Sesuai request)
                          if (role == "customer") ...[
                            _buildMenuItem(
                              icon: Icons.settings_outlined,
                              text: "Pengaturan",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 20, endIndent: 20),
                          ],

                          // 3. LOGOUT (Untuk Semua Role)
                          _buildMenuItem(
                            icon: Icons.logout,
                            text: "Keluar",
                            textColor: Colors.red,
                            iconColor: Colors.red,
                            isLast: true,
                            onTap: _showLogoutDialog,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    Text(
                      "Versi Aplikasi 1.0.0",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget Helper untuk Item Menu
  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color textColor = Colors.black87,
    Color iconColor = Colors.black54,
    bool isLast = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
      shape: isLast
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)))
          : null,
    );
  }
}