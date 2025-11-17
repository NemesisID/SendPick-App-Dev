import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import 'maps_screen.dart';

class ProtectedHomeScreen extends StatefulWidget {
  const ProtectedHomeScreen({super.key});

  @override
  State<ProtectedHomeScreen> createState() => _ProtectedHomeScreenState();
}

class _ProtectedHomeScreenState extends State<ProtectedHomeScreen> {
  int _currentIndex = 0;

  // Daftar halaman sesuai navbar
  final List<Widget> _pages = [
    const HomeContent(), // Index 0 - Home
    const MapsScreen(), // Index 1 - Maps
    const ScanPage(), // Index 2 - Scan
    const HistoryPage(), // Index 3 - History
    const ProfilePage(), // Index 4 - Profile
  ];

  void _onNavBarTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTapped,
      ),
    );
  }
}

// ========== HALAMAN HOME ==========
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: const Color(0xFF021E7B),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Home Content')),
    );
  }
}

// ========== HALAMAN SCAN (Sementara) ==========
class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        backgroundColor: const Color(0xFF021E7B),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 100, color: Color(0xFF021E7B)),
            SizedBox(height: 20),
            Text('Halaman Scan QR', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

// ========== HALAMAN HISTORY (Sementara) ==========
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color(0xFF021E7B),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 100, color: Color(0xFF021E7B)),
            SizedBox(height: 20),
            Text('Halaman History', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

// ========== HALAMAN PROFILE (Sementara) ==========
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF021E7B),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 100, color: Color(0xFF021E7B)),
            SizedBox(height: 20),
            Text('Halaman Profile', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}