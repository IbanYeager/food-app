import 'package:flutter/material.dart';
import 'package:test_application/screens/succes_screen.dart';
import 'package:intl/intl.dart'; // import intl untuk format rupiah
import 'package:test_application/services/cart_service.dart';

class PaymentPage extends StatefulWidget {
  final double total; // ✅ ganti dari Decimal ke double
  const PaymentPage({super.key, required this.total});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? selectedPayment;
  String? selectedEWallet;
  final TextEditingController cardController = TextEditingController();
  final TextEditingController bankController = TextEditingController();

  // Formatter rupiah tanpa desimal
  final NumberFormat formatRupiah =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  bool get isFormValid {
    if (selectedPayment == null) return false;
    if (selectedPayment == 'E-Wallet') return selectedEWallet != null;
    if (selectedPayment == 'Kartu Kredit/Debit') return cardController.text.isNotEmpty;
    if (selectedPayment == 'Transfer Bank') return bankController.text.isNotEmpty;
    return true;
  }

  @override
  void dispose() {
    cardController.dispose();
    bankController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pembayaran")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Total yang harus dibayar:",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              formatRupiah.format(widget.total), // ✅ tampilkan tanpa desimal
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Pilih metode pembayaran:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  // E-Wallet
                  RadioListTile<String>(
                    title: const Text("E-Wallet"),
                    value: "E-Wallet",
                    groupValue: selectedPayment,
                    onChanged: (value) {
                      setState(() {
                        selectedPayment = value;
                        selectedEWallet = null;
                      });
                    },
                    secondary: const Icon(Icons.account_balance_wallet),
                  ),
                  if (selectedPayment == "E-Wallet")
                    Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: Column(
                        children: ["DANA", "GoPay", "ShopeePay", "QRIS"]
                            .map((e) => RadioListTile<String>(
                                  title: Text(e),
                                  value: e,
                                  groupValue: selectedEWallet,
                                  onChanged: (v) => setState(() => selectedEWallet = v),
                                ))
                            .toList(),
                      ),
                    ),

                  // Kartu Kredit/Debit
                  RadioListTile<String>(
                    title: const Text("Kartu Kredit/Debit"),
                    value: "Kartu Kredit/Debit",
                    groupValue: selectedPayment,
                    onChanged: (value) {
                      setState(() {
                        selectedPayment = value;
                        cardController.clear();
                      });
                    },
                    secondary: const Icon(Icons.credit_card),
                  ),
                  if (selectedPayment == "Kartu Kredit/Debit")
                    Padding(
                      padding: const EdgeInsets.only(left: 40, right: 20, bottom: 10),
                      child: TextField(
                        controller: cardController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Masukkan nomor kartu",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),

                  // Transfer Bank
                  RadioListTile<String>(
                    title: const Text("Transfer Bank"),
                    value: "Transfer Bank",
                    groupValue: selectedPayment,
                    onChanged: (value) {
                      setState(() {
                        selectedPayment = value;
                        bankController.clear();
                      });
                    },
                    secondary: const Icon(Icons.money),
                  ),
                  if (selectedPayment == "Transfer Bank")
                    Padding(
                      padding: const EdgeInsets.only(left: 40, right: 20, bottom: 10),
                      child: TextField(
                        controller: bankController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Masukkan nomor rekening",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isFormValid
                    ? () {
                        // ✅ Hapus semua item di keranjang
                        CartService().cartItems.clear();

                        // ✅ Navigasi ke halaman sukses
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SuccessPage(),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Pesan Sekarang"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
