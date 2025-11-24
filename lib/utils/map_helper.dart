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
}