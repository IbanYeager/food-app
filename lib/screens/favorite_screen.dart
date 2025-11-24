// screens/favorite_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_application/services/menu_service.dart'; // Impor service menu
import 'package:intl/intl.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<dynamic> _favoriteMenus = [];
  bool _isLoading = true;

  // Formatter untuk mata uang
  final NumberFormat formatRupiah =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadFavoriteMenus();
  }

  Future<void> _loadFavoriteMenus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList('favorite_menus') ?? [];

      if (favoriteIds.isEmpty) {
        if (mounted) {
          setState(() {
            _favoriteMenus = [];
            _isLoading = false;
          });
        }
        return;
      }
      
      // Ambil SEMUA menu (asumsi API mendukung parameter 'limit' atau 'all')
      // Di sini kita ambil 100 item sebagai contoh, sesuaikan jika perlu
      final result = await MenuService.getMenus(page: 1, limit: 100);
      final allMenus = result['data'] as List<dynamic>? ?? [];

      // Filter menu berdasarkan ID yang tersimpan
      final favoriteMenusData = allMenus
          .where((menu) => favoriteIds.contains(menu['id'].toString()))
          .toList();

      if (mounted) {
        setState(() {
          _favoriteMenus = favoriteMenusData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Handle error, misalnya dengan menampilkan SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat favorit: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Favorit Saya'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        // Tambahkan tombol refresh
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavoriteMenus,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (_favoriteMenus.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada item favorit',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _favoriteMenus.length,
      itemBuilder: (context, index) {
        final menu = _favoriteMenus[index];
        final String nama = menu['nama'] ?? 'Nama tidak tersedia';
        final double harga = double.tryParse(menu['harga'].toString()) ?? 0.0;
        final String gambar = menu['gambar'] ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                gambar,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.restaurant, size: 40),
              ),
            ),
            title: Text(
              nama,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              formatRupiah.format(harga),
              style: const TextStyle(color: Colors.deepOrange),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.redAccent),
              onPressed: () async {
                // Hapus dari favorit dan muat ulang
                final prefs = await SharedPreferences.getInstance();
                final favoriteIds = prefs.getStringList('favorite_menus') ?? [];
                favoriteIds.remove(menu['id'].toString());
                await prefs.setStringList('favorite_menus', favoriteIds);
                _loadFavoriteMenus(); // Refresh list
              },
            ),
          ),
        );
      },
    );
  }
}