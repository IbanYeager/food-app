// 📂 utils/location_helper.dart
import 'dart:math';
import 'package:latlong2/latlong.dart';

class LocationHelper {
  static double hitungJarak(LatLng from, LatLng to) {
    const R = 6371; // radius bumi (km)
    double dLat = (to.latitude - from.latitude) * (pi / 180);
    double dLon = (to.longitude - from.longitude) * (pi / 180);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(from.latitude * (pi / 180)) *
            cos(to.latitude * (pi / 180)) *
            sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // hasil dalam km
  }
}
