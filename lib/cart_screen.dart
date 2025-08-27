import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;

  const CartScreen({super.key, required this.cartItems});

  @override
  Widget build(BuildContext context) {
    int total = cartItems.fold(0, (sum, item) => sum + (item['harga'] as int));

    return Scaffold(
      appBar: AppBar(title: const Text("Keranjang")),
      body: cartItems.isEmpty
          ? const Center(child: Text("Keranjang masih kosong"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return ListTile(
                        leading: Image.asset(item['gambar'], width: 50),
                        title: Text(item['nama']),
                        subtitle: Text("Rp ${item['harga']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            // TODO: hapus item dari cart
                          },
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text("Total: Rp $total"),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, "/payment");
                        },
                        child: const Text("Lanjut ke Pembayaran"),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
