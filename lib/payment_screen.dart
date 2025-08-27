import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedMethod = "Transfer Bank";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Metode Pembayaran")),
      body: Column(
        children: [
          RadioListTile(
            title: const Text("Transfer Bank"),
            value: "Transfer Bank",
            groupValue: selectedMethod,
            onChanged: (val) => setState(() => selectedMethod = val!),
          ),
          RadioListTile(
            title: const Text("COD (Bayar di Tempat)"),
            value: "COD",
            groupValue: selectedMethod,
            onChanged: (val) => setState(() => selectedMethod = val!),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, "/success");
            },
            child: const Text("Bayar Sekarang"),
          ),
        ],
      ),
    );
  }
}
