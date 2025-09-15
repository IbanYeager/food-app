// 📂 detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:test_application/services/cart_service.dart';
import 'package:test_application/services/menu_service.dart'; // Pastikan ini di-import
import '../../utils/location_helper.dart';
import '../../services/route_service.dart';

class DetailScreen extends StatefulWidget {
  final int id;
  final String nama;
  final double harga;
  final String gambar;
  final String deskripsi;
  final double latitude;
  final double longitude;

  const DetailScreen({
    super.key,
    required this.id,
    required this.nama,
    required this.harga,
    required this.gambar,
    required this.deskripsi,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final LatLng pembeliLatLng = LatLng(-6.917464, 107.619125);
  late LatLng tokoLatLng;
  List<LatLng> routePoints = [];
  int _quantity = 1;

  // State untuk data rekomendasi
  List<dynamic> _rekomendasiMenu = [];
  bool _isLoadingRekomendasi = true;

  final NumberFormat formatRupiah =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    tokoLatLng = LatLng(widget.latitude, widget.longitude);
    _loadRoute();
    _loadRekomendasi(); // Memuat data rekomendasi
  }

  Future<void> _loadRoute() async {
    try {
      final points = await RouteService.getRoute(tokoLatLng, pembeliLatLng);
      if (mounted) {
        setState(() => routePoints = points);
      }
    } catch (e) {
      debugPrint("Gagal mengambil rute: $e");
      if (mounted) {
        setState(() => routePoints = [tokoLatLng, pembeliLatLng]);
      }
    }
  }

  // Fungsi untuk mengambil data rekomendasi dari server
  Future<void> _loadRekomendasi() async {
    try {
      final result = await MenuService.getMenus(page: 1);
      final allMenus = result['data'] as List<dynamic>? ?? [];

      if (mounted) {
        setState(() {
          _rekomendasiMenu = allMenus
              .where((menu) => menu['id'].toString() != widget.id.toString())
              .take(4)
              .toList();
          _isLoadingRekomendasi = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil data rekomendasi: $e");
      if (mounted) {
        setState(() {
          _isLoadingRekomendasi = false;
        });
      }
    }
  }

  String _hitungEstimasiWaktu(double jarakKm) {
    const double kecepatanKmh = 25;
    const int waktuPersiapanMenit = 8;
    final double waktuPerjalananJam = jarakKm / kecepatanKmh;
    final int waktuPerjalananMenit = (waktuPerjalananJam * 60).round();
    final int totalEstimasi = waktuPerjalananMenit + waktuPersiapanMenit;
    final int batasBawah = totalEstimasi > 2 ? totalEstimasi - 2 : 1;
    final int batasAtas = totalEstimasi + 5;
    return "$batasBawah - $batasAtas menit";
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addToCart() {
    CartService().addItem({
      'id': widget.id,
      'nama': widget.nama,
      'harga': widget.harga,
      'qty': _quantity,
      'gambar': widget.gambar,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${widget.nama} (x$_quantity) ditambahkan ke keranjang"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final double jarak = LocationHelper.hitungJarak(tokoLatLng, pembeliLatLng);
    final String estimasi = _hitungEstimasiWaktu(jarak);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _buildBottomBar(context, textTheme, colorScheme),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, colorScheme),
          SliverToBoxAdapter(
            // KONTENER DIKEMBALIKAN KE POSISI SEMULA (TANPA TRANSFORM.TRANSLATE)
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderRow(textTheme, colorScheme),
                    const SizedBox(height: 16),
                    _buildTitleAndQuantityRow(textTheme),
                    const SizedBox(height: 8),
                    Text(
                      widget.deskripsi,
                      style: textTheme.bodyLarge?.copyWith(color: Colors.grey[600], height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    // BAGIAN INI TETAP MENGGUNAKAN FUNGSI REKOMENDASI
                    _buildRekomendasiSection(textTheme),
                    const SizedBox(height: 24),
                    _buildDeliveryInfo(textTheme, jarak, estimasi),
                    const SizedBox(height: 24),
                    Text("Lokasi Toko", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildMapCard(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 280.0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product_image_${widget.id}',
          // GAMBAR DIKEMBALIKAN KE KONDISI SEMULA (TANPA LENGKUNGAN BAWAH)
          child: ClipRRect(
            child: Image.network(
              widget.gambar,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.fastfood, size: 100, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(TextTheme textTheme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Chip(
          avatar: const Icon(Icons.star, color: Colors.white, size: 16),
          label: Text("4.5", style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        Text(
          formatRupiah.format(widget.harga),
          style: textTheme.headlineSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleAndQuantityRow(TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.nama,
            style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                onPressed: _decrementQuantity,
              ),
              Text(
                '$_quantity',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: _incrementQuantity,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // FUNGSI INI TETAP ADA UNTUK MENAMPILKAN DATA REKOMENDASI
  Widget _buildRekomendasiSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Rekomendasi", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: _isLoadingRekomendasi
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _rekomendasiMenu.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final menu = _rekomendasiMenu[index];
                    final String gambar = menu['gambar']?.toString() ?? '';
                    final String nama = menu['nama']?.toString() ?? 'Menu';

                    return SizedBox(
                      width: 100,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder( // Menggunakan PageRouteBuilder agar transisi tetap halus
                              opaque: false,
                              pageBuilder: (context, animation, secondaryAnimation) => DetailScreen(
                                id: int.tryParse(menu['id'].toString()) ?? 0,
                                nama: nama,
                                harga: double.tryParse(menu['harga'].toString()) ?? 0.0,
                                gambar: gambar,
                                deskripsi: menu['deskripsi']?.toString() ?? '',
                                latitude: double.tryParse(menu['latitude'].toString()) ?? 0.0,
                                longitude: double.tryParse(menu['longitude'].toString()) ?? 0.0,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  gambar,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(color: Colors.grey[200]),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              nama,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDeliveryInfo(TextTheme textTheme, double jarak, String estimasi) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.route_outlined,
              label: "Jarak Pengantaran",
              value: "${jarak.toStringAsFixed(1)} km",
              textTheme: textTheme,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.timer_outlined,
              label: "Estimasi Tiba",
              value: estimasi,
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value, required TextTheme textTheme}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 24),
        const SizedBox(width: 16),
        Text(label, style: textTheme.bodyLarge),
        const Spacer(),
        Text(value, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMapCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: tokoLatLng,
            initialZoom: 14.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.test.app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  color: Colors.blueAccent,
                  strokeWidth: 5,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: tokoLatLng,
                  width: 80,
                  height: 80,
                  child: const Icon(Icons.store, color: Colors.deepOrange, size: 35),
                ),
                Marker(
                  point: pembeliLatLng,
                  width: 80,
                  height: 80,
                  child: const Icon(Icons.home, color: Colors.blue, size: 35),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      // BOTTOM BAR DIKEMBALIKAN KE KONDISI SEMULA (TANPA LENGKUNGAN)
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: ElevatedButton(
        onPressed: _addToCart,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          "Tambah ke Keranjang",
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}