import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/maps_screen.dart';
import 'screens/vehicle_selection_screen.dart';
import 'screens/protected_home_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

// Handler untuk background message - HARUS top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
  debugPrint('Background message data: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Inisialisasi Notification Service
    final notificationService = NotificationService();
    try {
      await notificationService.initialize();
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      // FCM mungkin gagal di emulator tanpa Google Play Services
      debugPrint('Warning: Notification service failed to initialize: $e');
      debugPrint('Push notifications may not work on this device');
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

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
