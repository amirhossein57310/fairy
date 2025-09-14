import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:get/get.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';
import '../controllers/bluetooth_controller.dart';
import '../controllers/battery_controller.dart';
import 'permission_status_screen.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final BluetoothController controller = Get.find<BluetoothController>();
  final BatteryController batteryController = Get.put(BatteryController());
  final RxBool isCharging = false.obs;
  final Battery _battery = Battery();
  final RxDouble batteryTemperature = 0.0.obs;

  @override
  void initState() {
    super.initState();
    _initBatteryMonitoring();
  }

  void _showDevicesSheet(ThemeData theme, {required bool onlyConnected}) {
    final devices = onlyConnected
        ? controller.devices
            .where((d) => controller.isDeviceConnected(d))
            .toList()
        : controller.devices;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.devices, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      onlyConnected ? 'Connected Devices' : 'Available Devices',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (devices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        onlyConnected ? 'No connected devices' : 'No devices',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  )
                else
                  ...devices.map((device) {
                    final isConnected = controller.isDeviceConnected(device);
                    return ListTile(
                      leading: Icon(
                        Icons.bluetooth_rounded,
                        color: isConnected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      title: Text(controller.getDeviceName(device)),
                      subtitle: Text(controller.getDeviceId(device)),
                      trailing: Icon(
                        isConnected
                            ? Icons.link_rounded
                            : Icons.link_off_rounded,
                        color: isConnected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        if (isConnected) {
                          controller.disconnectFromDevice(device);
                        } else {
                          controller.connectToDevice(device);
                        }
                      },
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _initBatteryMonitoring() async {
    try {
      // Get initial battery temperature (if available)
      await _updateBatteryTemperature();

      // Listen to battery state changes
      _battery.onBatteryStateChanged.listen((BatteryState state) {
        _updateBatteryTemperature();
      });

      // Update temperature periodically
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 30));
        await _updateBatteryTemperature();
        return true;
      });
    } catch (e) {
      print('Error initializing battery monitoring: $e');
    }
  }

  Future<void> _updateBatteryTemperature() async {
    try {
      // Note: Most mobile devices don't expose battery temperature through standard APIs
      // This is a placeholder for when temperature data becomes available
      // For now, we'll use a simulated temperature based on battery level
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      // Simulate temperature based on battery level and charging state
      double temp = 25.0; // Base temperature
      if (state == BatteryState.charging) {
        temp += 5.0; // Charging increases temperature
      }
      if (level > 80) {
        temp += 3.0; // High battery level increases temperature
      } else if (level < 20) {
        temp += 2.0; // Low battery level can also increase temperature
      }

      batteryTemperature.value = temp;
    } catch (e) {
      print('Error getting battery temperature: $e');
      // Set a default temperature if we can't get it
      batteryTemperature.value = 25.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to close the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                  _closeApp();
                },
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fairy Bluetooth'),
          actions: [
            IconButton(
              icon: const Icon(Icons.security),
              onPressed: () => Get.to(() => PermissionStatusScreen()),
              tooltip: 'Permission Status',
            ),
            IconButton(
              icon: const Icon(Icons.devices),
              tooltip: 'Devices',
              onPressed: () {
                final bool hasConnectedDevice = controller.devices
                    .any((d) => controller.isDeviceConnected(d));
                if (!hasConnectedDevice) {
                  controller.showSystemDevices();
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            //    _buildStatusCard(theme),
            _buildBatteryInfoCard(theme),
            _buildDevicesList(theme),
            _buildChargingControl(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    return Obx(() => Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 0,
            color: _getStatusCardColor(theme),
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusIconColor(theme).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getStatusIcon(),
                          color: _getStatusIconColor(theme),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          controller.statusMessage.value,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                  if (_isPermissionIssue()) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => controller.refreshPermissions(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Permissions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _openSettings(),
                          icon: const Icon(Icons.settings),
                          label: const Text('Settings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildBatteryInfoCard(ThemeData theme) {
    return Obx(() => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Battery Level Indicator with liquid animation and top cap
                  Column(
                    children: [
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
                        height: 120,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: LiquidLinearProgressIndicator(
                            value: batteryController.currentBatteryLevel.value /
                                100,
                            direction: Axis.vertical,
                            borderRadius: 8,
                            borderWidth: 2,
                            borderColor:
                                theme.colorScheme.outline.withOpacity(0.3),
                            backgroundColor: theme.colorScheme.surface,
                            valueGradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _getBatteryColor(batteryController
                                        .currentBatteryLevel.value)
                                    .withOpacity(0.7),
                                _getBatteryColor(batteryController
                                    .currentBatteryLevel.value),
                              ],
                            ),
                            center: Text(
                              '${batteryController.currentBatteryLevel.value}%',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Battery Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.battery_charging_full,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Battery Information',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Temperature Row
                        Row(
                          children: [
                            Icon(
                              Icons.thermostat,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Temperature: ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${batteryTemperature.value.toStringAsFixed(1)} °C',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Battery State
                        Row(
                          children: [
                            Icon(
                              Icons.battery_full,
                              color: theme.colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Status: ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _getBatteryStatusText(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Color _getBatteryColor(int level) {
    if (level > 50) {
      return Colors.green;
    } else if (level > 20) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getBatteryStatusText() {
    final level = batteryController.currentBatteryLevel.value;
    if (level > 80) {
      return 'Good';
    } else if (level > 50) {
      return 'Normal';
    } else if (level > 20) {
      return 'Low';
    } else {
      return 'Critical';
    }
  }

  Color _getStatusCardColor(ThemeData theme) {
    if (_isPermissionIssue()) {
      return Colors.orange.withOpacity(0.1);
    } else if (_isError()) {
      return Colors.red.withOpacity(0.1);
    } else {
      return theme.colorScheme.primary.withOpacity(0.1);
    }
  }

  Color _getStatusIconColor(ThemeData theme) {
    if (_isPermissionIssue()) {
      return Colors.orange;
    } else if (_isError()) {
      return Colors.red;
    } else {
      return theme.colorScheme.primary;
    }
  }

  IconData _getStatusIcon() {
    if (_isPermissionIssue()) {
      return Icons.security;
    } else if (_isError()) {
      return Icons.error_outline;
    } else {
      return Icons.info_outline_rounded;
    }
  }

  bool _isPermissionIssue() {
    final message = controller.statusMessage.value.toLowerCase();
    return message.contains('permission') || message.contains('required');
  }

  bool _isError() {
    final message = controller.statusMessage.value.toLowerCase();
    return message.contains('error') || message.contains('failed');
  }

  // Method to open settings based on platform
  Future<void> _openSettings() async {
    if (Platform.isAndroid) {
      // For Android, try to open app-specific settings
      try {
        await openAppSettings();
      } catch (e) {
        // Fallback to general settings
        print('Error opening app settings: $e');
        // You could also use a custom method to open Android settings
      }
    } else {
      // For iOS, use the standard method
      await openAppSettings();
    }
  }

  Widget _buildDevicesList(ThemeData theme) {
    return Expanded(
      child: Obx(() {
        final bool hasConnectedDevice = controller.devices
            .any((device) => controller.isDeviceConnected(device));
        final visibleDevices = hasConnectedDevice
            ? controller.devices
                .where((d) => controller.isDeviceConnected(d))
                .toList()
            : controller.devices;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: visibleDevices.length,
          itemBuilder: (context, index) {
            final device = visibleDevices[index];
            final isConnected = controller.isDeviceConnected(device);
            final isConnecting = controller.isDeviceConnecting(device);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isConnected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => isConnected
                    ? controller.disconnectFromDevice(device)
                    : controller.connectToDevice(device),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isConnected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.bluetooth_rounded,
                          color: isConnected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.getDeviceName(device),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isConnected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.getDeviceId(device),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isConnecting)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        )
                      else
                        Icon(
                          isConnected
                              ? Icons.link_rounded
                              : Icons.link_off_rounded,
                          color: isConnected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildChargingControl(ThemeData theme) {
    return Obx(() {
      final bool hasConnectedDevice = controller.devices
          .any((device) => controller.isDeviceConnected(device));
      final connectedDevice = controller.devices.firstWhereOrNull(
        (device) => controller.isDeviceConnected(device),
      );
      final targetBattery = batteryController.targetBatteryLevel.value;
      final currentBattery = batteryController.currentBatteryLevel.value;

      if (!hasConnectedDevice || connectedDevice == null) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Battery Level Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Battery: $currentBattery%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Target: $targetBattery%',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Battery Level Slider
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: theme.colorScheme.primary,
                    inactiveTrackColor:
                        theme.colorScheme.primary.withOpacity(0.2),
                    thumbColor: theme.colorScheme.primary,
                    overlayColor: theme.colorScheme.primary.withOpacity(0.1),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: targetBattery.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '$targetBattery%',
                    onChanged: (value) {
                      batteryController.setTargetBatteryLevel(value.round());
                      // Update ESP32 when target changes
                      if (isCharging.value) {
                        controller.sendBatteryInfo(
                          connectedDevice,
                          currentBattery,
                          value.round(),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Charging Control',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    isCharging.value = !isCharging.value;
                    if (isCharging.value) {
                      controller.sendString(connectedDevice, "true");
                    } else {
                      controller.sendString(connectedDevice, "false");
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isCharging.value
                            ? [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withOpacity(0.8),
                              ]
                            : [
                                Colors.grey.shade300,
                                Colors.grey.shade400,
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isCharging.value
                                  ? theme.colorScheme.primary
                                  : Colors.grey)
                              .withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        isCharging.value
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isCharging.value
                      ? 'Charging to $targetBattery%'
                      : 'Not Charging',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isCharging.value
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _closeApp() async {
    // Stop background service
    FlutterBackgroundService().invoke('stopService');
    // Disconnect all devices
    for (var device in controller.devices) {
      if (controller.isDeviceConnected(device)) {
        await device.disconnect();
      }
    }

    // Platform-specific exit handling
    if (Platform.isAndroid) {
      // Android-specific: Remove task from recent apps and exit
      const platform = MethodChannel('com.fairy.app/system');
      try {
        await platform.invokeMethod('removeFromRecents');
      } catch (e) {
        print('Error removing from recents: $e');
      }
      // Force exit the app on Android
      SystemNavigator.pop(animated: true);
    } else if (Platform.isIOS) {
      // iOS-specific: Just pop the app (iOS handles app lifecycle differently)
      // Note: On iOS, apps don't typically "exit" - they go to background
      // This will close the app gracefully
      SystemNavigator.pop(animated: true);
    } else {
      // For other platforms, use the default behavior
      SystemNavigator.pop(animated: true);
    }
  }
}
