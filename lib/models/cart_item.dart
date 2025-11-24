// models/cart_item.dart

class CartItem {
  final String id;
  final String nama;
  final double harga;
  final String gambar;
  int quantity;

  CartItem({
    required this.id,
    required this.nama,
    required this.harga,
    required this.gambar,
    this.quantity = 1,
  });

  // Fungsi untuk mempermudah konversi dari Map (data dari API/menu)
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'].toString(),
      nama: map['nama'] ?? 'Unknown Product',
      harga: double.tryParse(map['harga'].toString()) ?? 0.0,
      gambar: map['gambar'] ?? '',
      quantity: map['qty'] ?? 1,
    );
  }
}