import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_application/services/menu_service.dart';
import 'package:test_application/screens/detail_screen.dart';
import 'package:intl/intl.dart';

// Import ProfileScreen tidak lagi dibutuhkan di sini
// import 'package:test_application/screens/profile_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State untuk data pengguna dan UI
  String? namaUser;
  String? fotoUser;

  // State untuk filter dan search
  String selectedCategory = "Makanan"; // Kategori default
  final TextEditingController searchController = TextEditingController();
  bool _isPromoFilterActive = false;

  // State untuk list menu
  List<dynamic> allMenus = [];
  List<dynamic> filteredMenus = []; // Untuk menampung hasil search

  // State untuk Pagination (Lazy Loading)
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 1;

  // Formatter untuk mata uang Rupiah
  final NumberFormat formatRupiah =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadInitialMenus(); // Memuat data menu pertama kali

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoading &&
          _hasMoreData) {
        _loadMoreMenus();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        namaUser = prefs.getString("nama")?.trim().isNotEmpty == true
            ? prefs.getString("nama")
            : "Pengguna";
        fotoUser = prefs.getString("foto");
      });
    }
  }

  Future<void> _loadInitialMenus() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMoreData = true;
      allMenus.clear();
      filteredMenus.clear();
      searchController.clear();
    });

    try {
      final result = await MenuService.getMenus(
        page: _currentPage,
        category: _isPromoFilterActive ? null : selectedCategory.toLowerCase(),
        isPromo: _isPromoFilterActive,
      );
      final newMenus = result['data'] as List<dynamic>? ?? [];

      setState(() {
        allMenus.addAll(newMenus);
        _applySearchFilter();

        if (newMenus.length < 10) {
          _hasMoreData = false;
        }
        _currentPage++;
      });
    } catch (e) {
      // Handle error jika diperlukan
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreMenus() async {
    setState(() => _isLoading = true);

    try {
      final result = await MenuService.getMenus(
        page: _currentPage,
        category: _isPromoFilterActive ? null : selectedCategory.toLowerCase(),
        isPromo: _isPromoFilterActive,
      );
      final newMenus = result['data'] as List<dynamic>? ?? [];

      setState(() {
        if (newMenus.isNotEmpty) {
          allMenus.addAll(newMenus);
          _applySearchFilter();
          _currentPage++;
        }
        if (newMenus.length < 10) {
          _hasMoreData = false;
        }
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applySearchFilter() {
    String query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredMenus = List.from(allMenus);
      } else {
        filteredMenus = allMenus.where((menu) {
          final nama = menu['nama']?.toString().toLowerCase() ?? '';
          return nama.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // TAMBAHKAN KEMBALI: Scaffold sebagai pembungkus utama halaman ini
    // Scaffold ini hanya akan berisi 'body'
    return Scaffold(
      // HAPUS: SafeArea tidak lagi dibutuhkan karena Scaffold sudah menanganinya
      body: RefreshIndicator(
        onRefresh: _loadInitialMenus,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Padding ini untuk memberi jarak dari status bar atas
              const SizedBox(height: 16),
              // 🔹 Header atas
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Selamat Datang, ${namaUser ?? 'Pengguna'} 👋",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // GestureDetector dihapus karena navigasi profil via BottomNav
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: (fotoUser != null && fotoUser!.isNotEmpty)
                          ? NetworkImage(fotoUser!)
                          : const AssetImage("assets/images/profile.png")
                              as ImageProvider,
                      onBackgroundImageError: (exception, stackTrace) {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 🔹 Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => _applySearchFilter(),
                  decoration: InputDecoration(
                    hintText: "Cari menu...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 Kategori
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildCategory("Makanan", Icons.fastfood),
                    _buildCategory("Minuman", Icons.local_drink),
                    _buildCategory("Dessert", Icons.cake),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 Banner Promo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isPromoFilterActive = !_isPromoFilterActive;
                    });
                    _loadInitialMenus();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: _isPromoFilterActive
                          ? Colors.orange[800]
                          : Colors.deepOrange,
                      borderRadius: BorderRadius.circular(16),
                      border: _isPromoFilterActive
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isPromoFilterActive
                                    ? "Promo Aktif!"
                                    : "Promo Spesial",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isPromoFilterActive
                                    ? "Ketuk untuk mematikan filter"
                                    : "Dapatkan diskon untuk menu pilihan!",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Image.asset(
                          'assets/images/image-removebg-preview.png',
                          height: 60,
                          width: 60,
                        )
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Daftar Menu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: (filteredMenus.isEmpty && !_isLoading)
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text("Tidak ada menu ditemukan"),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredMenus.length + (_hasMoreData ? 1 : 0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          if (index == filteredMenus.length) {
                            return const Center(
                              child: CircularProgressIndicator(color: Colors.orange),
                            );
                          }

                          final menu = filteredMenus[index];
                          final int id =
                              int.tryParse(menu['id'].toString()) ?? 0;
                          final String nama =
                              menu['nama']?.toString() ?? 'Unknown';
                          final double harga =
                              double.tryParse(menu['harga'].toString()) ?? 0.0;
                          String gambar = menu['gambar']?.toString() ?? '';

                          return InkWell(
                            onTap: () {
                              final double latitude =
                                  double.tryParse(menu['latitude'].toString()) ??
                                      0.0;
                              final double longitude =
                                  double.tryParse(menu['longitude'].toString()) ??
                                      0.0;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailScreen(
                                    id: id,
                                    nama: nama,
                                    harga: harga,
                                    gambar: gambar,
                                    deskripsi: menu['deskripsi'] ?? '',
                                    latitude: latitude,
                                    longitude: longitude,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 5,
                                    offset: const Offset(2, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: Image.network(
                                      gambar,
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          height: 100,
                                          color: Colors.grey[200],
                                          alignment: Alignment.center,
                                          child: Icon(Icons.broken_image,
                                              color: Colors.grey[400]),
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nama,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatRupiah.format(harga),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Widget Kategori
  Widget _buildCategory(String title, IconData icon) {
    final bool isSelected = selectedCategory == title && !_isPromoFilterActive;
    return GestureDetector(
      onTap: () {
        if (selectedCategory == title && !_isPromoFilterActive) return;

        setState(() {
          _isPromoFilterActive = false;
          selectedCategory = title;
        });
        _loadInitialMenus();
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isSelected ? Colors.orange : Colors.orange[100],
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : Colors.orange[700],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.orange : Colors.black,
              ),
            )
          ],
        ),
      ),
    );
  }
}