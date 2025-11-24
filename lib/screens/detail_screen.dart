// ===== lib/screens/detail_screen.dart (TANPA MAP) =====
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:test_application/providers/cart_provider.dart';
import 'package:test_application/services/menu_service.dart';

class DetailScreen extends StatefulWidget {
  final int id;
  final String nama;
  final double harga;
  final String gambar;
  final String deskripsi;
  // 💡 Parameter lokasi dihapus karena tidak diperlukan lagi di sini

  const DetailScreen({
    super.key,
    required this.id,
    required this.nama,
    required this.harga,
    required this.gambar,
    required this.deskripsi,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _quantity = 1;
  List<dynamic> _rekomendasiMenu = [];
  bool _isLoadingRekomendasi = true;
  final NumberFormat formatRupiah =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadRekomendasi();
  }

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
      if (mounted) setState(() => _isLoadingRekomendasi = false);
    }
  }

  void _incrementQuantity() {
    setState(() => _quantity++);
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _addToCart() {
    context.read<CartProvider>().addItem({
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _buildBottomBar(context, textTheme, colorScheme),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, colorScheme),
          SliverToBoxAdapter(
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
                    const SizedBox(height: 16),
                    
                    // Deskripsi
                    const Text("Deskripsi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      widget.deskripsi.isEmpty ? "Tidak ada deskripsi." : widget.deskripsi,
                      style: textTheme.bodyLarge?.copyWith(color: Colors.grey[600], height: 1.5),
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Rekomendasi
                    _buildRekomendasiSection(textTheme),
                    
                    // 💡 Peta Dihapus dari sini
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
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product_image_${widget.id}',
          child: Image.network(
            widget.gambar,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.fastfood, size: 100, color: Colors.grey),
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
          label: Text("4.5",
              style: textTheme.titleMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildRekomendasiSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Menu Lainnya",
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                    return SizedBox(
                      width: 100,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(
                                id: int.tryParse(menu['id'].toString()) ?? 0,
                                nama: menu['nama']?.toString() ?? 'Menu',
                                harga: double.tryParse(menu['harga'].toString()) ?? 0.0,
                                gambar: menu['gambar']?.toString() ?? '',
                                deskripsi: menu['deskripsi']?.toString() ?? '',
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
                                  menu['gambar']?.toString() ?? '',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(color: Colors.grey[200]),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              menu['nama']?.toString() ?? 'Menu',
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

  Widget _buildBottomBar(BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(color: Colors.white),
      child: ElevatedButton(
        onPressed: _addToCart,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          "Tambah ke Keranjang",
          style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}