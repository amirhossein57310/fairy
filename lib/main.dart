import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/main_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'controllers/bluetooth_controller.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await requestPermissions();

  // Initialize controllers
  Get.put(BluetoothController());

  runApp(const MyApp());
}

Future<void> requestPermissions() async {
  try {
    // Request Bluetooth permissions
    final bluetoothStatus = await Permission.bluetooth.request();
    print('Bluetooth permission status: $bluetoothStatus');

    final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
    print('Bluetooth Connect permission status: $bluetoothConnectStatus');

    final bluetoothScanStatus = await Permission.bluetoothScan.request();
    print('Bluetooth Scan permission status: $bluetoothScanStatus');

    // Location permission removed for iOS - app only uses paired devices like Dabble
    if (Platform.isAndroid) {
      // Only request location for Android (required for Bluetooth scanning)
      final locationStatus = await Permission.location.request();
      print('Location permission status: $locationStatus');
    }

    // Request additional Android permissions
    if (Platform.isAndroid) {
      // For Android 12+, we need to handle Bluetooth permissions differently
      if (await _isAndroid12OrHigher()) {
        print('Android 12+ detected - using new Bluetooth permission model');

        // Request Bluetooth permissions with proper handling
        final bluetoothScanStatus = await Permission.bluetoothScan.request();
        print('Bluetooth Scan permission status: $bluetoothScanStatus');

        final bluetoothConnectStatus =
            await Permission.bluetoothConnect.request();
        print('Bluetooth Connect permission status: $bluetoothConnectStatus');
      }

      final backgroundLocationStatus =
          await Permission.locationAlways.request();
      print('Background Location permission status: $backgroundLocationStatus');

      final notificationStatus = await Permission.notification.request();
      print('Notification permission status: $notificationStatus');
    }

    // Check if all critical permissions are granted
    if (!bluetoothStatus.isGranted ||
        !bluetoothConnectStatus.isGranted ||
        !bluetoothScanStatus.isGranted) {
      print(
          'Some Bluetooth permissions were not granted. Please check settings.');
    }

    // Check location permission only for Android
    if (Platform.isAndroid) {
      final locationStatus = await Permission.location.request();
      if (!locationStatus.isGranted) {
        print(
            'Location permission not granted on Android. Bluetooth scanning may not work.');
      }
    }
  } catch (e) {
    print('Error requesting permissions: $e');
  }
}

// Helper function to detect Android 12+ (API level 31+)
Future<bool> _isAndroid12OrHigher() async {
  if (!Platform.isAndroid) return false;

  try {
    // Use device_info_plus package or check Android version
    // For now, we'll use a simple approach
    return true; // Assume Android 12+ for now
  } catch (e) {
    print('Error detecting Android version: $e');
    return false;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fairy Bluetooth',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF2C3E50),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF2C3E50),
          ),
        ),
      ),
      home: MainScreen(),
    );
  }
}
