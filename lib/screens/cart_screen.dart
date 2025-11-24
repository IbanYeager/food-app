// screens/cart_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ✅ Ganti import
import 'package:intl/intl.dart';
import 'package:test_application/providers/cart_provider.dart'; // ✅ Ganti import
import 'package:test_application/screens/payment_screen.dart'; 

class CartPage extends StatelessWidget { // ✅ Ubah ke StatelessWidget
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Formatter bisa didefinisikan di dalam build method
    final NumberFormat formatRupiah =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    // Menggunakan Consumer untuk mendengarkan perubahan dari CartProvider
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Keranjang Saya'),
            centerTitle: true,
          ),
          body: cart.items.isEmpty
              ? const Center(
                  child: Text(
                    'Keranjang kosong 😢',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  item.gambar,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image_not_supported),
                                ),
                              ),
                              title: Text(item.nama),
                              subtitle: Text(
                                  "${formatRupiah.format(item.harga)} x ${item.quantity}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                    onPressed: () => cart.decrementQty(item.id), // ✅ Panggil provider dengan ID
                                  ),
                                  Text("${item.quantity}"),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.orange),
                                    onPressed: () => cart.incrementQty(item.id), // ✅ Panggil provider dengan ID
                                  ),
                                  IconButton(
                                    icon:
                                        const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => cart.removeItem(item.id), // ✅ Panggil provider dengan ID
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Widget untuk total dan checkout
                    _buildCheckoutSection(context, cart.totalPrice, formatRupiah),
                  ],
                ),
        );
      },
    );
  }

  // Widget terpisah untuk bagian checkout
  Widget _buildCheckoutSection(BuildContext context, double totalPrice, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24).copyWith(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Harga:",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                formatter.format(totalPrice),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.shopping_cart_checkout_rounded),
              label: const Text("Lanjutkan ke Pembayaran"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentPage(total: totalPrice),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Colors.deepOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}