import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/maps_screen.dart';
import 'screens/vehicle_selection_screen.dart';
import 'screens/protected_home_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SendPick',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/vehicle_selection': (context) => const VehicleSelectionScreen(),
        '/home': (context) => const ProtectedHomeScreen(),
        '/maps': (context) => const MapsScreen(),
      },
    );
  }
}

// Global instance of AuthService
final AuthService authService = AuthService();
