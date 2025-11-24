import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Fungsi utama untuk mendapatkan lokasi dan alamat pengguna
  Future<Map<String, dynamic>> getCurrentLocation() async {
    // 1. Cek apakah layanan lokasi di perangkat aktif
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Jika tidak aktif, kembalikan error
      return Future.error('Layanan lokasi tidak aktif.');
    }

    // 2. Cek perizinan lokasi oleh pengguna
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Jika izin ditolak, minta izin
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Jika tetap ditolak, kembalikan error
        return Future.error('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Jika ditolak permanen, kembalikan error
      return Future.error(
          'Izin lokasi ditolak secara permanen, harap aktifkan dari pengaturan.');
    }

    // 3. Jika izin diberikan, ambil posisi saat ini
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // 4. Ubah koordinat (lat, long) menjadi alamat yang bisa dibaca
    String address = await _getAddressFromLatLng(position);

    // 5. Kembalikan data lengkap
    return {
      'position': position,
      'address': address,
    };
  }

  // Fungsi helper untuk mengubah LatLng ke alamat (Reverse Geocoding)
  Future<String> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Format alamat agar lebih rapi
        return "${place.street}, ${place.subLocality}, ${place.locality}";
      } else {
        return "Alamat tidak ditemukan";
      }
    } catch (e) {
      return "Gagal mendapatkan alamat";
    }
  }
}