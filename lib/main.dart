import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/main_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'controllers/bluetooth_controller.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await requestPermissions();

  // Initialize controllers
  Get.put(BluetoothController());

  runApp(const MyApp());
}

Future<void> requestPermissions() async {
  await Permission.bluetooth.request();
  await Permission.bluetoothConnect.request();
  await Permission.bluetoothScan.request();
  await Permission.location.request();
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
