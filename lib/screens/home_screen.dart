import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import '../widgets/pending_order_card.dart';
import '../main.dart'; // Import main to access authService
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Default: Home

  @override
  void initState() {
    super.initState();
    
    // Check if user has selected a vehicle when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!authService.hasSelectedVehicle) {
        // If no vehicle is selected, redirect to vehicle selection
        Navigator.pushReplacementNamed(context, '/vehicle-selection');
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Di sini Anda bisa tambahkan navigasi ke halaman lain jika perlu
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset(
          'assets/images/logo.png', // Pastikan path logo benar
          height: 40,
        ),
        actions: [
          // Add vehicle info to the app bar if a vehicle is selected
          if (authService.hasSelectedVehicle)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      color: Colors.blue.shade600,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'B 1234 XY', // Would be dynamic in real app
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      Text(
                        'Avanza', // Would be dynamic in real app
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.blue.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    onSelected: (value) {
                      if (value == 'change') {
                        // Navigate to vehicle selection screen to change vehicle
                        Navigator.pushReplacementNamed(context, '/vehicle-selection');
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'change',
                        child: Row(
                          children: [
                            Icon(Icons.local_shipping, size: 18),
                            SizedBox(width: 8),
                            Text('Change Vehicle'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF003D9E),
              child: const Text('AH', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat Pagi,',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const Text(
              'Ahmad Marzuki',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Show vehicle status - update based on whether a vehicle is selected
            if (authService.hasSelectedVehicle)
              Row(
                children: [
                  const Icon(Icons.directions_car, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Sedang dalam perjalanan',
                    style: TextStyle(color: Colors.blue),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to vehicle selection screen to change vehicle
                      Navigator.pushReplacementNamed(context, '/vehicle-selection');
                    },
                    icon: Icon(Icons.local_shipping_outlined, size: 16),
                    label: const Text('Ganti Kendaraan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Belum pilih kendaraan',
                    style: TextStyle(color: Colors.orange),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to vehicle selection screen
                      Navigator.pushReplacementNamed(context, '/vehicle-selection');
                    },
                    icon: Icon(Icons.local_shipping_outlined, size: 16),
                    label: const Text('Pilih'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            const Text(
              'Order Aktif',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory, color: Colors.blue[800]),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Menuju Pickup',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Ambil paket dari pengiriman',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SP-2025-001'),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text('15,5km'),
                            Text('ETA: 15 menit', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Progress', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.6,
                      backgroundColor: Colors.grey[200],
                      color: Colors.blue[800],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pickup', style: TextStyle(fontWeight: FontWeight.bold)),
                              const Text('Jl. Gunung Anyar No.16, Surabaya'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
                              const Text('Jl. Panjang Jiwo No 21, Surabaya'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Kristal Anastasia'),
                        const Spacer(),
                        const Text('+62 821 2344 1234'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.navigation),
                        label: const Text('Navigasi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[800],
                          side: BorderSide(color: Colors.blue[800]!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Pending',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            PendingOrderCard(
              pesanan: 'Borneo',
              pickupLocation: 'kertajaya',
              deliveryLocation: 'Semolowaru',
              onReject: () {
                // Handle tolak order
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order ditolak')),
                );
              },
              onAccept: () {
                // Handle terima order
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order diterima')),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}