import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    // 💡 OSRM membutuhkan format: Longitude,Latitude (Kebalik dari LatLng biasa)
    final String startCoord = "${start.longitude},${start.latitude}";
    final String endCoord = "${end.longitude},${end.latitude}";

    final url = Uri.parse(
      "https://router.project-osrm.org/route/v1/driving/$startCoord;$endCoord?overview=full&geometries=geojson",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Cek apakah rute ditemukan
        if (data['routes'] == null || (data['routes'] as List).isEmpty) {
          return [];
        }

        final geometry = data['routes'][0]['geometry'];
        final coordinates = geometry['coordinates'] as List;

        // Konversi kembali ke LatLng (Lat, Long) untuk Flutter Map
        return coordinates.map((coord) {
          return LatLng(
            double.parse(coord[1].toString()), // Latitude (indeks 1 di GeoJSON)
            double.parse(coord[0].toString()), // Longitude (indeks 0 di GeoJSON)
          );
        }).toList();
      } else {
        print("Gagal mengambil rute. Status: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error RouteService: $e");
      return [];
    }
  }
}