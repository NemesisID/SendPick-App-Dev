import 'package:flutter/material.dart';

class MapHelper {
  // Membuat marker dengan icon default berwarna
  static Widget createColoredMarker(Color color) {
    return Icon(
      Icons.location_on,
      color: color,
      size: 40,
      shadows: [
        Shadow(
          blurRadius: 10.0,
          color: Colors.black26,
          offset: Offset(1.0, 1.0),
        ),
      ],
    );
  }

  // Membuat marker dengan icon mobil untuk lokasi driver
  static Widget createCarMarker() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF021E7B),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.directions_car, color: Colors.white, size: 28),
    );
  }

  // Membuat marker untuk lokasi pengantaran dengan nomor urutan
  static Widget createDestinationMarker({
    required int index,
    required bool isActive,
    required bool isCompleted,
  }) {
    Color bgColor;
    Color textColor = Colors.white;
    IconData icon;

    if (isCompleted) {
      bgColor = Colors.grey;
      icon = Icons.check;
    } else if (isActive) {
      bgColor = Colors.green;
      icon = Icons.navigation;
    } else {
      bgColor = Colors.orange;
      icon = Icons.location_on;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child:
            isCompleted
                ? Icon(icon, color: textColor, size: 24)
                : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
      ),
    );
  }

  // Warna polyline untuk rute aktif
  static Color get activeRouteColor => const Color(0xFF021E7B);

  // Warna polyline untuk rute tidak aktif
  static Color get inactiveRouteColor => Colors.grey.withOpacity(0.5);
}
