import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/bluetooth_controller.dart';
import 'dart:io' show Platform;

class PermissionStatusScreen extends StatelessWidget {
  final BluetoothController controller = Get.find<BluetoothController>();

  PermissionStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Status'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, bool>>(
        future: controller.checkPermissionStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final permissions = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (Platform.isAndroid) ...[
                // Android 12+ specific permissions
                _buildPermissionCard(
                  theme,
                  'Bluetooth Scan',
                  'Required for Android 12+ to discover Bluetooth devices',
                  permissions['bluetoothScan'] ?? false,
                  Icons.bluetooth_searching,
                  () => _requestPermission(Permission.bluetoothScan),
                ),
                const SizedBox(height: 16),
                _buildPermissionCard(
                  theme,
                  'Bluetooth Connect',
                  'Required for Android 12+ to connect to Bluetooth devices',
                  permissions['bluetoothConnect'] ?? false,
                  Icons.bluetooth_connected,
                  () => _requestPermission(Permission.bluetoothConnect),
                ),
              ] else ...[
                // iOS and older Android permissions
                _buildPermissionCard(
                  theme,
                  'Bluetooth',
                  'Allows the app to use Bluetooth',
                  permissions['bluetooth'] ?? false,
                  Icons.bluetooth,
                  () => _requestPermission(Permission.bluetooth),
                ),
                const SizedBox(height: 16),
                _buildPermissionCard(
                  theme,
                  'Bluetooth Connect',
                  'Allows the app to connect to Bluetooth devices',
                  permissions['bluetoothConnect'] ?? false,
                  Icons.bluetooth_connected,
                  () => _requestPermission(Permission.bluetoothConnect),
                ),
                const SizedBox(height: 16),
                _buildPermissionCard(
                  theme,
                  'Bluetooth Scan',
                  'Allows the app to scan for Bluetooth devices',
                  permissions['bluetoothScan'] ?? false,
                  Icons.bluetooth_searching,
                  () => _requestPermission(Permission.bluetoothScan),
                ),
              ],
              // Location permission removed for iOS - app only uses paired devices like Dabble
              if (Platform.isAndroid) ...[
                const SizedBox(height: 16),
                _buildPermissionCard(
                  theme,
                  'Location',
                  'Required for Bluetooth scanning on Android',
                  permissions['location'] ?? false,
                  Icons.location_on,
                  () => _requestPermission(Permission.location),
                ),
              ],
              if (Platform.isAndroid) ...[
                const SizedBox(height: 16),
                _buildPermissionCard(
                  theme,
                  'Background Location',
                  'Recommended for better Bluetooth functionality',
                  permissions['backgroundLocation'] ?? false,
                  Icons.location_on,
                  () => _requestPermission(Permission.locationAlways),
                ),
                const SizedBox(height: 16),
                _buildPermissionCard(
                  theme,
                  'Notifications',
                  'Recommended for background service',
                  permissions['notifications'] ?? false,
                  Icons.notifications,
                  () => _requestPermission(Permission.notification),
                ),
              ],
              const SizedBox(height: 32),
              _buildInfoCard(theme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPermissionCard(
    ThemeData theme,
    String title,
    String description,
    bool isGranted,
    IconData icon,
    VoidCallback onRequest,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isGranted
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isGranted ? Colors.green : Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isGranted ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isGranted ? 'Granted' : 'Required',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      elevation: 1,
      color: theme.colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Permission Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Bluetooth permissions are required to connect to your Fairy device\n'
              '• Location permission is only required on Android for Bluetooth scanning\n'
              '• iOS devices work like Dabble - only Bluetooth permission needed\n'
              '• If permissions are denied, you can enable them in Settings',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      Get.snackbar(
        'Permission Required',
        'Please enable ${permission.toString().split('.').last} permission in Settings',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Show a separate dialog with settings button
      Get.dialog(
        AlertDialog(
          title: const Text('Permission Required'),
          content: Text(
              'Please enable ${permission.toString().split('.').last} permission in Settings to use this feature.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }
}
