import 'package:flutter/material.dart';

class OrderInfoScreen extends StatelessWidget {
  const OrderInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: ambil data pesanan dari API atau local storage
    return Scaffold(
      appBar: AppBar(title: const Text("Informasi Pesanan")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(title: Text("Pesanan #12345")),
          ListTile(title: Text("Status: Diproses")),
          ListTile(title: Text("Total: Rp 50.000")),
        ],
      ),
    );
  }
}
