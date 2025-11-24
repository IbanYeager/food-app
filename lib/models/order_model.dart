// ===== lib/models/order_model.dart (MODIFIKASI) =====
import 'package:intl/intl.dart';

class Order {
  final String orderNumber;
  final String status;
  final String date;
  final double total;
  // 💡 BARU: Tambahkan field lokasi
  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;

  Order({
    required this.orderNumber,
    required this.status,
    required this.date,
    required this.total,
    // 💡 BARU:
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    String formattedDate;
    try {
      final rawDate = json['date'];
      if (rawDate != null && rawDate.isNotEmpty) {
        final parsedDate = DateTime.tryParse(rawDate); 
        if (parsedDate != null) {
          formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(parsedDate);
        } else {
          formattedDate = rawDate;
        }
      } else {
        formattedDate = 'Tanggal tidak tersedia';
      }
    } catch (e) {
      formattedDate = 'Format tanggal salah';
    }

    return Order(
      orderNumber: json['orderNumber']?.toString() ?? 'Unknown',
      status: json['status']?.toString() ?? 'Pending',
      date: formattedDate,
      total: double.tryParse(json['total']?.toString() ?? '0.0') ?? 0.0,
      
      // 💡 BARU: Parse data lokasi dari JSON
      originLat: double.tryParse(json['origin_lat']?.toString() ?? '0.0') ?? 0.0,
      originLng: double.tryParse(json['origin_lng']?.toString() ?? '0.0') ?? 0.0,
      destinationLat: double.tryParse(json['destination_lat']?.toString() ?? '0.0') ?? 0.0,
      destinationLng: double.tryParse(json['destination_lng']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderNumber': orderNumber,
      'status': status,
      'date': date,
      'total': total,
    };
  }
}