// 📂 detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/location_helper.dart';
import '../services/route_service.dart';

class DetailScreen extends StatefulWidget {
  final String nama;
  final int harga;
  final String gambar;

  const DetailScreen({
    super.key,
    required this.nama,
    required this.harga,
    required this.gambar,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final LatLng tokoLatLng = LatLng(-6.9175, 107.6191);
  final LatLng pembeliLatLng = LatLng(-6.9039, 107.6186);

  List<LatLng> routePoints = [];
  String selectedMode = "motor"; // default: motor

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      final points = await RouteService.getRoute(tokoLatLng, pembeliLatLng);
      setState(() {
        routePoints = points;
      });
    } catch (e) {
      debugPrint("Gagal ambil rute: $e");
    }
  }

  /// Hitung estimasi waktu berdasarkan mode transportasi
  double hitungWaktu(double jarakKm, String mode) {
    double kecepatan; // km/jam

    switch (mode) {
      case "jalan":
        kecepatan = 5; // jalan kaki 5 km/jam
        break;
      case "motor":
        kecepatan = 40; // motor 40 km/jam
        break;
      case "mobil":
        kecepatan = 30; // mobil 30 km/jam (macet wkwk)
        break;
      default:
        kecepatan = 40;
    }

    return (jarakKm / kecepatan) * 60; // hasil dalam menit
  }

  @override
  Widget build(BuildContext context) {
    final double jarak = LocationHelper.hitungJarak(tokoLatLng, pembeliLatLng);
    final double estimasi = hitungWaktu(jarak, selectedMode);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Detail Makanan",
          style: TextStyle(color: Colors.black87),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF3C623),
                Color(0xFFF3C623),
                Color.fromARGB(0, 243, 198, 35),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gambar
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  widget.gambar,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image,
                        size: 100, color: Colors.grey);
                  },
                ),
              ),
            ),

            // Card detail
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 5,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama
                      Text(
                        widget.nama,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Harga
                      Row(
                        children: [
                          Text(
                            "Rp${widget.harga.toString()}",
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Deskripsi
                      const Text(
                        "Deskripsi makanan ini sangat enak dan cocok untuk semua kalangan. "
                        "Dibuat dengan bahan berkualitas tinggi.",
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Peta
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: tokoLatLng,
                              initialZoom: 14,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                subdomains: const ['a', 'b', 'c'],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: tokoLatLng,
                                    width: 60,
                                    height: 60,
                                    child: const Icon(Icons.store,
                                        color: Colors.red, size: 35),
                                  ),
                                  Marker(
                                    point: pembeliLatLng,
                                    width: 60,
                                    height: 60,
                                    child: const Icon(Icons.home,
                                        color: Colors.blue, size: 35),
                                  ),
                                ],
                              ),
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: routePoints.isNotEmpty
                                        ? routePoints
                                        : [tokoLatLng, pembeliLatLng],
                                    color: const Color.fromARGB(255, 15, 170, 231),
                                    strokeWidth: 4,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Jarak + estimasi
                      Row(
                        children: [
                          const Icon(Icons.route,
                              size: 20, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(
                            "Jarak: ${jarak.toStringAsFixed(2)} km",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Icon(Icons.timer,
                              size: 20, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(
                            "${estimasi.toStringAsFixed(0)} menit",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Dropdown pilih mode transportasi
                      Row(
                        children: [
                          const Icon(Icons.directions_bike,
                              size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: selectedMode,
                            items: const [
                              DropdownMenuItem(
                                  value: "jalan", child: Text("Jalan Kaki")),
                              DropdownMenuItem(
                                  value: "motor", child: Text("Motor")),
                              DropdownMenuItem(
                                  value: "mobil", child: Text("Mobil")),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedMode = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Tombol
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text("${widget.nama} ditambahkan ke keranjang")),
                    );
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF3C623), Color(0xFFFF9800)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Text(
                        "Tambah ke Keranjang",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
