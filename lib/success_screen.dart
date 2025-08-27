import 'package:flutter/material.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text("Pembayaran Berhasil!", style: TextStyle(fontSize: 20)),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/order_info");
              },
              child: const Text("Lihat Pesanan"),
            ),
          ],
        ),
      ),
    );
  }
}
