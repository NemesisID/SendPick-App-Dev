import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'vehicle_selection_screen.dart';
import '../main.dart'; // Import main to access authService

class ProtectedHomeScreen extends StatefulWidget {
  const ProtectedHomeScreen({super.key});

  @override
  State<ProtectedHomeScreen> createState() => _ProtectedHomeScreenState();
}

class _ProtectedHomeScreenState extends State<ProtectedHomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Check if the user has a selected vehicle
    if (!authService.hasSelectedVehicle) {
      // If no vehicle is selected, redirect to vehicle selection
      return const VehicleSelectionScreen();
    }
    
    // If vehicle is selected, show the home screen
    return const HomeScreen();
  }
}