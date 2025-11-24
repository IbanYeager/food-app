import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PhotoMarker extends Marker {
  PhotoMarker({
    required LatLng point,
    required String? photoUrl,
    bool isDriver = false, // True = Hijau (Kurir), False = Biru (Customer)
  }) : super(
          point: point,
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // 1. Pin Background
              Icon(
                Icons.location_on,
                size: 60,
                color: isDriver ? Colors.green : Colors.blue,
              ),
              // 2. Foto Profil Bulat di Tengah
              Positioned(
                top: 5,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 2),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: (photoUrl != null && photoUrl.isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : const AssetImage('assets/images/profil.png') as ImageProvider,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
}