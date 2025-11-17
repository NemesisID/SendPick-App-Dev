import 'package:flutter/material.dart';

class PendingOrderCard extends StatelessWidget {
  final String pesanan;
  final String pickupLocation;
  final String deliveryLocation;
  final VoidCallback onReject;
  final VoidCallback onAccept;

  const PendingOrderCard({
    super.key,
    required this.pesanan,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.onReject,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Baru Telah Masuk',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text('Pesanan : $pesanan'),
            Text('Lokasi Pickup : $pickupLocation'),
            Text('Lokasi Delivery : $deliveryLocation'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tombol Tolak
                GestureDetector(
                  onTap: onReject,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                // Tombol Terima
                GestureDetector(
                  onTap: onAccept,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}