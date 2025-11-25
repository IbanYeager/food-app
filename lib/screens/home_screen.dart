import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_application/providers/cart_provider.dart';
import 'package:test_application/services/location_service.dart';
import 'package:test_application/services/menu_service.dart';
import 'package:test_application/screens/detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:test_application/screens/store_location_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? namaUser;
  String? fotoUser;
  String selectedCategory = "Makanan";
  final TextEditingController searchController = TextEditingController();
  bool _isPromoFilterActive = false;
  final List<dynamic> _allMenus = [];
  List<dynamic> _filteredMenus = [];
  Set<String> _favoriteMenuIds = {};
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  bool _isInitialDataLoaded = false;
  final NumberFormat formatRupiah =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  Position? _currentPosition;
  String _currentAddress = "Memuat lokasi...";
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _initializePage();
    _setupScrollListener();
    searchController.addListener(_applySearchFilter);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialDataLoaded) {
      _loadFavorites();
      _fetchMenus(isInitial: true);
      _isInitialDataLoaded = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.removeListener(_applySearchFilter);
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _loadUser();
    await _loadFavorites();
    _getCurrentLocation();
  }

  Future<void> _refreshData() async {
    _isInitialDataLoaded = false;
    await _getCurrentLocation();
    await _loadFavorites();
    await _fetchMenus(isInitial: true);
  }
  
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMoreData) {
        _fetchMenus();
      }
    });
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

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorite_menus') ?? [];
    if (mounted) {
      setState(() {
        _favoriteMenuIds = favoriteIds.toSet();
      });
    }
  }

  Future<void> _toggleFavorite(String menuId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteMenuIds.contains(menuId)) {
        _favoriteMenuIds.remove(menuId);
      } else {
        _favoriteMenuIds.add(menuId);
      }
    });
    await prefs.setStringList('favorite_menus', _favoriteMenuIds.toList());
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = locationData['position'];
          _currentAddress = locationData['address'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = "Gagal memuat lokasi";
        });
      }
    }
  }

  Future<void> _fetchMenus({bool isInitial = false}) async {
    if (_isLoading || !mounted) return;
    setState(() => _isLoading = true);
    
    if (isInitial) {
      _currentPage = 1;
      _hasMoreData = true;
      _allMenus.clear();
      _filteredMenus.clear();
    }

    try {
      final result = await MenuService.getMenus(
        page: _currentPage,
        category: _isPromoFilterActive ? null : selectedCategory.toLowerCase(),
        isPromo: _isPromoFilterActive,
      );
      final newMenus = result['data'] as List<dynamic>? ?? [];
      final int totalItems = int.tryParse(result['total_items'].toString()) ?? 0;
      
      if (!mounted) return;

      setState(() {
        _allMenus.addAll(newMenus);
        _applySearchFilter();
        
        if (_allMenus.length >= totalItems) {
          _hasMoreData = false;
        } else {
          _currentPage++;
        }
      });
    } catch (e) {
      debugPrint("Error fetching menus: $e");
      if (mounted) setState(() => _hasMoreData = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _applySearchFilter() {
    final String query = searchController.text.toLowerCase();
    if (!mounted) return;
    setState(() {
      if (query.isEmpty) {
        _filteredMenus = List.from(_allMenus);
      } else {
        _filteredMenus = _allMenus.where((menu) {
          final nama = menu['nama']?.toString().toLowerCase() ?? '';
          return nama.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.deepOrange,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 8),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildCategoryList(),
              const SizedBox(height: 16),
              _buildPromoBanner(),
              const SizedBox(height: 20),
              _isLoading && _allMenus.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator(color: Colors.orange)))
                  : _buildMenuGrid(),
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Pastikan sejajar vertikal
        children: [
          // --- 1. LOGO APLIKASI (DITAMBAHKAN DISINI) ---
          ClipRRect(
            borderRadius: BorderRadius.circular(8), // Opsional: agar sudut logo agak melengkung
            child: Image.asset(
              'assets/images/Red and White Simple Food Logo.png',
              height: 50, // Sesuaikan ukuran logo
              width: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Tampilkan icon jika gambar gagal dimuat
                return const Icon(Icons.fastfood, color: Colors.deepOrange, size: 40);
              },
            ),
          ),
          const SizedBox(width: 12), // Jarak antara logo dan teks

          // --- 2. TEKS SELAMAT DATANG & LOKASI (EXISTING) ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Selamat Datang, ${namaUser ?? 'Pengguna'} 👋",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Font sedikit dikecilkan agar muat
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Widget Lokasi
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StoreLocationScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.deepOrange, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Lihat Lokasi Toko",
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            decoration: TextDecoration.underline
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- 3. FOTO PROFIL USER (EXISTING) ---
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 20, // Sedikit disesuaikan ukurannya
            backgroundColor: Colors.grey[200],
            backgroundImage: (fotoUser != null && fotoUser!.isNotEmpty)
                ? NetworkImage(fotoUser!)
                : const AssetImage("assets/images/profil.png") as ImageProvider,
            onBackgroundImageError: (exception, stackTrace) {},
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextField(
        controller: searchController,
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
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildCategoryItem("Makanan", Icons.fastfood),
          _buildCategoryItem("Minuman", Icons.local_drink),
          _buildCategoryItem("Dessert", Icons.cake),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    final bool isSelected = selectedCategory == title && !_isPromoFilterActive;
    return GestureDetector(
      onTap: () {
        if (isSelected) return;
        setState(() {
          _isPromoFilterActive = false;
          selectedCategory = title;
        });
        _fetchMenus(isInitial: true);
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isSelected ? Colors.orange : Colors.orange[100],
              child: Icon(icon, size: 28, color: isSelected ? Colors.white : Colors.orange[700]),
            ),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.orange : Colors.black,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: InkWell(
        onTap: () {
          setState(() => _isPromoFilterActive = !_isPromoFilterActive);
          _fetchMenus(isInitial: true);
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: _isPromoFilterActive ? Colors.orange[800] : Colors.deepOrange,
            borderRadius: BorderRadius.circular(16),
            border: _isPromoFilterActive ? Border.all(color: Colors.white, width: 2) : null,
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
                      _isPromoFilterActive ? "Mode Promo Aktif!" : "Promo Spesial", 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      _isPromoFilterActive ? "Klik untuk melihat semua menu" : "Dapatkan diskon untuk menu pilihan!", 
                      style: const TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Image.asset('assets/images/image-removebg-preview.png', height: 60, width: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    if (_filteredMenus.isEmpty && !_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Tidak ada menu ditemukan untuk filter ini")));
    }
    
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredMenus.length + (_hasMoreData && _isLoading ? 1 : 0), 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        if (index == _filteredMenus.length) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }
        final menu = _filteredMenus[index];
        return _buildMenuItemCard(menu);
      },
    );
  }
  
  Widget _buildMenuItemCard(Map<String, dynamic> menu) {
    final String menuId = menu['id'].toString();
    final bool isFavorite = _favoriteMenuIds.contains(menuId);

    return GestureDetector(
      onTap: () => _navigateToDetail(menu),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, offset: const Offset(2, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    menu['gambar']?.toString() ?? '',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image, color: Colors.grey[400]),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.redAccent : Colors.white,
                      ),
                      onPressed: () => _toggleFavorite(menuId),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu['nama']?.toString() ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          formatRupiah.format(double.tryParse(menu['harga'].toString()) ?? 0.0),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.orange),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, color: Colors.deepOrange, size: 20),
                        onPressed: () {
                          context.read<CartProvider>().addItem(menu);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${menu['nama']} ditambahkan ke keranjang"),
                              duration: const Duration(seconds: 1),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(dynamic menu) {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lokasi belum siap, coba lagi.")),
      );
      _getCurrentLocation(); 
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          id: int.tryParse(menu['id'].toString()) ?? 0,
          nama: menu['nama']?.toString() ?? 'Unknown',
          harga: double.tryParse(menu['harga'].toString()) ?? 0.0,
          gambar: menu['gambar']?.toString() ?? '',
          deskripsi: menu['deskripsi'] ?? '',
        ),
      ),
    );
  }
}