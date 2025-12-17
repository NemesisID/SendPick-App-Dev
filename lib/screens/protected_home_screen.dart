import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import 'home_screen.dart';
import 'maps_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';

class ProtectedHomeScreen extends StatefulWidget {
  const ProtectedHomeScreen({super.key});

  @override
  State<ProtectedHomeScreen> createState() => _ProtectedHomeScreenState();
}

class _ProtectedHomeScreenState extends State<ProtectedHomeScreen> {
  int _currentIndex = 0;

  void _onNavBarTapped(int index) {
    if (index == 2) {
      // Scan - open as fullscreen route
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ScanScreen(
                onBackTap: () {
                  Navigator.pop(context); // Return to previous page
                },
              ),
        ),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeScreen(), // Index 0 - Home
      const MapsScreen(), // Index 1 - Maps
      const SizedBox(), // Index 2 - Placeholder (Scan opens as route)
      const HistoryScreen(), // Index 3 - History
      const ProfileScreen(), // Index 4 - Profile
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTapped,
      ),
    );
  }
}
