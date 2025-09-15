import 'package:flutter/foundation.dart';

// 1. Tambahkan 'with ChangeNotifier'
class CartService with ChangeNotifier {
  // Singleton pattern sudah benar, tidak perlu diubah
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  // 2. Jadikan list ini private (dengan underscore)
  final List<Map<String, dynamic>> _cartItems = [];

  // 3. Buat getter publik untuk mengakses list dari luar
  List<Map<String, dynamic>> get cartItems => _cartItems;

  void addItem(Map<String, dynamic> newItem) {
    // Pastikan semua referensi menggunakan _cartItems
    int index = _cartItems.indexWhere((item) => item['id'] == newItem['id']);
    
    if (index != -1) {
      // Jika item sudah ada, tambah quantity-nya
      _cartItems[index]['qty'] += newItem['qty'];
    } else {
      // Jika item baru, tambahkan ke list
      _cartItems.add(newItem);
    }

    // 4. Beri tahu semua widget yang 'mendengarkan' bahwa ada perubahan
    notifyListeners();
  }

  void incrementQty(int index) {
    _cartItems[index]['qty']++;
    // Beri tahu listener
    notifyListeners();
  }

  void decrementQty(int index) {
    if (_cartItems[index]['qty'] > 1) {
      _cartItems[index]['qty']--;
      // Beri tahu listener
      notifyListeners();
    }
  }

  void removeItem(int index) {
    _cartItems.removeAt(index);
    // Beri tahu listener
    notifyListeners();
  }

  // Fungsi baru untuk mengosongkan keranjang
  void clearCart() {
    _cartItems.clear();
    // Beri tahu listener
    notifyListeners();
  }

  double getTotalPrice() {
    double total = 0.0;
    for (var item in _cartItems) {
      // Asumsi harga dan qty selalu ada dan valid setelah ditambahkan
      total += (item['harga'] * item['qty']);
    }
    return total;
  }
}