// providers/cart_provider.dart

import 'package:flutter/foundation.dart';
import 'package:test_application/models/cart_item.dart';

class CartProvider with ChangeNotifier {
  static final CartProvider _instance = CartProvider._internal();
  factory CartProvider() => _instance;
  CartProvider._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + (item.harga * item.quantity));
  }
  
  int get itemCount {
    return _items.length;
  }

  // ✅ FUNGSI YANG DISEMPURNAKAN
  void addItem(Map<String, dynamic> menuData) {
    final String id = menuData['id'].toString();
    // Ambil kuantitas dari data yang dikirim, jika tidak ada, default-nya 1
    final int quantityToAdd = menuData['qty'] ?? 1;
    final index = _items.indexWhere((item) => item.id == id);

    if (index != -1) {
      // Jika item sudah ada, tambah quantity-nya sejumlah yang baru ditambahkan
      _items[index].quantity += quantityToAdd;
    } else {
      // Jika item baru, tambahkan ke list.
      // Constructor fromMap akan menggunakan 'qty' jika ada di dalam menuData.
      _items.add(CartItem.fromMap(menuData));
    }
    
    notifyListeners();
  }

  void incrementQty(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQty(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return; 

    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}