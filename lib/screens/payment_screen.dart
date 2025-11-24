// ===== lib/screens/payment_page.dart (MODIFIKASI) =====
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_application/providers/cart_provider.dart';
import 'package:test_application/screens/succes_screen.dart';
import 'package:intl/intl.dart';
import 'package:test_application/services/order_service.dart';
// 💡 BARU: Import
import 'package:test_application/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class PaymentPage extends StatefulWidget {
  final double total;
  const PaymentPage({super.key, required this.total});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? selectedPayment;
  String? selectedEWallet;
  final TextEditingController cardController = TextEditingController();
  final TextEditingController bankController = TextEditingController();

  final NumberFormat formatRupiah =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  final Map<String, String> eWalletLogos = {
    "DANA": "assets/images/dana.png",
    "GoPay": "assets/images/gopay.png",
    "ShopeePay": "assets/images/shopeepay.jpeg",
    "QRIS": "assets/images/qris.png",
  };
  
  bool _isLoading = false;
  // 💡 BARU: Buat instance service lokasi
  final LocationService _locationService = LocationService();

  bool get isFormValid {
    if (selectedPayment == null) return false;
    if (selectedPayment == 'E-Wallet') return selectedEWallet != null;
    if (selectedPayment == 'Kartu Kredit/Debit')
      return cardController.text.isNotEmpty;
    if (selectedPayment == 'Transfer Bank') return bankController.text.isNotEmpty;
    return true;
  }

  @override
  void dispose() {
    cardController.dispose();
    bankController.dispose();
    super.dispose();
  }

  Future<void> _processOrder() async {
    if (!isFormValid) return;

    setState(() => _isLoading = true);

    final cart = context.read<CartProvider>();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id")?.toString() ?? "0"; 

    if (userId == "0") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User ID tidak ditemukan. Harap login ulang.")),
      );
      setState(() => _isLoading = false);
      return;
    }

    // 💡 BARU: Ambil lokasi user sebelum checkout
    LatLng userLocation;
    try {
      final locationData = await _locationService.getCurrentLocation();
      final Position position = locationData['position'];
      userLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mendapatkan lokasi Anda: $e")),
      );
      setState(() => _isLoading = false);
      return;
    }
    // ------------------------------------

    // 💡 MODIFIKASI: Panggil OrderService dengan lokasi
    final result = await OrderService.createOrder(
      userId: userId,
      total: widget.total,
      items: cart.items,
      userLocation: userLocation, // 💡 Masukkan lokasi
    );

    if (!mounted) return; 

    if (result['success'] == true) {
      cart.clearCart();
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SuccessPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuat pesanan: ${result['message']}")),
      );
    }

    setState(() => _isLoading = false);
  }
  
  // ... (sisa build method _buildPaymentTitle dan build(BuildContext context) Anda TETAP SAMA)
  // ...
  Widget _buildPaymentTitle(String assetName, String title) {
    return Row(
      children: [
        Image.asset(assetName, width: 40, height: 25, fit: BoxFit.contain),
        const SizedBox(width: 16),
        Text(title),
      ],
    );
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
              formatRupiah.format(widget.total),
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
                  RadioListTile<String>(
                    title: const Row(children: [
                      Icon(Icons.account_balance_wallet, color: Colors.deepPurple),
                      SizedBox(width: 16),
                      Text("E-Wallet")
                    ]),
                    value: "E-Wallet",
                    groupValue: selectedPayment,
                    onChanged: (value) {
                      setState(() {
                        selectedPayment = value;
                        selectedEWallet = null;
                      });
                    },
                  ),
                  if (selectedPayment == "E-Wallet")
                    Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: Column(
                        children: eWalletLogos.keys
                            .map((eWalletName) => RadioListTile<String>(
                                  title: _buildPaymentTitle(
                                      eWalletLogos[eWalletName]!, eWalletName),
                                  value: eWalletName,
                                  groupValue: selectedEWallet,
                                  onChanged: (v) =>
                                      setState(() => selectedEWallet = v),
                                ))
                            .toList(),
                      ),
                    ),
                  RadioListTile<String>(
                    title: _buildPaymentTitle(
                        "assets/images/credit_card.png", "Kartu Kredit/Debit"),
                    value: "Kartu Kredit/Debit",
                    groupValue: selectedPayment,
                    onChanged: (value) {
                      setState(() {
                        selectedPayment = value;
                        cardController.clear();
                      });
                    },
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
                  RadioListTile<String>(
                    title: _buildPaymentTitle(
                        "assets/images/bank_transfer.png", "Transfer Bank"),
                    value: "Transfer Bank",
                    groupValue: selectedPayment,
                    onChanged: (value) {
                      setState(() {
                        selectedPayment = value;
                        bankController.clear();
                      });
                    },
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
                onPressed: (isFormValid && !_isLoading) ? _processOrder : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,),
                      )
                    : const Text("Pesan Sekarang"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}