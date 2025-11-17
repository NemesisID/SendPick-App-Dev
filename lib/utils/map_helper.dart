import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapHelper {
  // Membuat custom marker dari asset
  static Future<BitmapDescriptor> createCustomMarkerFromAsset(
    String assetPath,
    int width,
  ) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteData = await frameInfo.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  // Membuat marker dengan icon default berwarna
  static BitmapDescriptor createColoredMarker(Color color) {
    double hue = 0;
    if (color == Colors.blue) {
      hue = BitmapDescriptor.hueBlue;
    } else if (color == Colors.green) {
      hue = BitmapDescriptor.hueGreen;
    } else if (color == Colors.orange) {
      hue = BitmapDescriptor.hueOrange;
    } else if (color == Colors.red) {
      hue = BitmapDescriptor.hueRed;
    }
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }
}