import 'package:flutter/material.dart';
import 'package:test_application/services/cart_service.dart';
import 'package:intl/intl.dart';
import 'package:test_application/screens/payment_screen.dart'; // ✅ import PaymentPage

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService cartService = CartService();

  // Formatter rupiah tanpa desimal
  final NumberFormat formatRupiah =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  void incrementQty(int index) {
    setState(() {
      cartService.incrementQty(index);
    });
  }

  void decrementQty(int index) {
    setState(() {
      cartService.decrementQty(index);
    });
  }

  void removeItem(int index) {
    setState(() {
      cartService.removeItem(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = cartService.cartItems;
    final totalPrice = cartService.getTotalPrice();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
      ),
      body: cartItems.isEmpty
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
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      double harga = item['harga'] is double
                          ? item['harga']
                          : double.tryParse(item['harga'].toString()) ?? 0.0;
                      int qty = item['qty'] ?? 1;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(item['nama']),
                          subtitle:
                              Text("${formatRupiah.format(harga)} x $qty"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => decrementQty(index),
                              ),
                              Text("$qty"),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => incrementQty(index),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => removeItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total: ${formatRupiah.format(totalPrice)}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // ✅ Navigasi ke PaymentPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PaymentPage(total: totalPrice), // kirim total
                            ),
                          );
                        },
                        child: const Text("Checkout"),
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
