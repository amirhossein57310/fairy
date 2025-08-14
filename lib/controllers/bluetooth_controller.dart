import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as flutter_blue;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'package:get_storage/get_storage.dart';

class BluetoothController extends GetxController {
  final RxList<flutter_blue.BluetoothDevice> devices =
      <flutter_blue.BluetoothDevice>[].obs;
  final RxString statusMessage = ''.obs;
  final Rx<flutter_blue.BluetoothDevice?> lastConnectedDevice =
      Rx<flutter_blue.BluetoothDevice?>(null);
  static const String LAST_DEVICE_ID_KEY = 'last_connected_device_id';
  final _storage = GetStorage();

  bool _isLocked = false;
  Completer<void>? _lock;

  @override
  void onInit() async {
    super.onInit();

    // Check if Bluetooth is on, if not request to turn it on
    if (!await flutter_blue.FlutterBluePlus.isAvailable) {
      statusMessage.value = "Bluetooth is not available on this device";
      return;
    }

    if (!await flutter_blue.FlutterBluePlus.isOn) {
      statusMessage.value = "Please turn on Bluetooth";
      // Request to turn on Bluetooth
      await flutter_blue.FlutterBluePlus.turnOn();
      // Wait for Bluetooth to turn on
      await Future.delayed(const Duration(seconds: 2));
      if (!await flutter_blue.FlutterBluePlus.isOn) {
        statusMessage.value = "Failed to turn on Bluetooth";
        return;
      }
    }

    // Load last connected device ID
    final lastDeviceId = _storage.read(LAST_DEVICE_ID_KEY);
    if (lastDeviceId != null) {
      // Try to find and connect to the last device
      final pairedDevices = await flutter_blue.FlutterBluePlus.bondedDevices;
      final lastDevice = pairedDevices.firstWhereOrNull(
          (device) => device.remoteId.toString() == lastDeviceId);
      if (lastDevice != null) {
        lastConnectedDevice.value = lastDevice;
        await connectToDevice(lastDevice);
      }
    }
  }

  Future<void> _takeMutex() async {
    while (_isLocked) {
      _lock = Completer<void>();
      await _lock?.future;
    }
    _isLocked = true;
  }

  void _giveMutex() {
    _isLocked = false;
    if (_lock != null && !_lock!.isCompleted) {
      _lock!.complete();
    }
    _lock = null;
  }

  Future<bool> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // For Android, check both Bluetooth and location permissions
        if (!await Permission.bluetoothConnect.isGranted) {
          final bluetoothConnectStatus =
              await Permission.bluetoothConnect.request();
          if (!bluetoothConnectStatus.isGranted) {
            statusMessage.value =
                "Bluetooth connect permission is required for Android. Please enable it in Settings > Apps > Fairy Bluetooth > Permissions > Bluetooth";
            return false;
          }
        }

        if (!await Permission.location.isGranted) {
          final locationStatus = await Permission.location.request();
          if (!locationStatus.isGranted) {
            statusMessage.value =
                "Location permission is required for Bluetooth scanning on Android. Please enable it in Settings > Apps > Fairy Bluetooth > Permissions > Location";
            return false;
          }
        }
      } else if (Platform.isIOS) {
        // For iOS, only check Bluetooth permissions (like Dabble)
        if (!await Permission.bluetooth.isGranted) {
          final bluetoothStatus = await Permission.bluetooth.request();
          if (!bluetoothStatus.isGranted) {
            statusMessage.value =
                "Bluetooth permission is required. Please enable it in Settings > Privacy & Security > Bluetooth";
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      statusMessage.value = "Error checking permissions: $e";
      return false;
    }
  }

  Future<void> showSystemDevices() async {
    try {
      if (!await _requestPermissions()) {
        return;
      }

      devices.clear();
      statusMessage.value = "Getting paired devices...";

      List<flutter_blue.BluetoothDevice> pairedDevices =
          await flutter_blue.FlutterBluePlus.bondedDevices;

      // If we have a last connected device, only show that one
      if (lastConnectedDevice.value != null) {
        final lastDevice = pairedDevices.firstWhereOrNull((device) =>
            device.remoteId.toString() ==
            lastConnectedDevice.value!.remoteId.toString());
        if (lastDevice != null) {
          devices.add(lastDevice);
          statusMessage.value = "Found last connected device";
          return;
        }
      }

      // Otherwise show all paired devices
      for (var device in pairedDevices) {
        devices.add(device);
      }

      if (devices.isEmpty) {
        statusMessage.value = "No paired Bluetooth devices found";
      } else {
        statusMessage.value = "Found ${devices.length} paired device(s)";
      }
    } catch (e) {
      statusMessage.value = "Error: $e";
    }
  }

  // Get device name
  String getDeviceName(flutter_blue.BluetoothDevice device) {
    return device.platformName;
  }

  // Get device ID (MAC address)
  String getDeviceId(flutter_blue.BluetoothDevice device) {
    return device.remoteId.toString();
  }

  bool isDeviceConnected(flutter_blue.BluetoothDevice device) {
    return device.isConnected;
  }

  bool isDeviceConnecting(flutter_blue.BluetoothDevice device) {
    return device.connectionState ==
        flutter_blue.BluetoothConnectionState.connecting;
  }

  Future<void> connectToDevice(flutter_blue.BluetoothDevice device) async {
    try {
      if (!await _requestPermissions()) {
        return;
      }

      statusMessage.value = "Connecting to ${getDeviceName(device)}...";

      await device.connect();
      await device.discoverServices();

      // Store the connected device
      lastConnectedDevice.value = device;
      await _storage.write(LAST_DEVICE_ID_KEY, device.remoteId.toString());

      // Update device list to show only the connected device
      devices.clear();
      devices.add(device);

      // Send "up" command when connected
      await sendString(device, "up");

      statusMessage.value = "Connected to ${getDeviceName(device)}";
    } catch (e) {
      statusMessage.value = "Error connecting to ${getDeviceName(device)}: $e";
    }
  }

  Future<void> disconnectFromDevice(flutter_blue.BluetoothDevice device) async {
    try {
      if (!await _requestPermissions()) {
        return;
      }

      statusMessage.value = "Disconnecting from ${getDeviceName(device)}...";

      // Send "down" command before disconnecting
      await sendString(device, "down");

      await device.disconnect();
      lastConnectedDevice.value = null;
      await _storage.remove(LAST_DEVICE_ID_KEY);

      // Show all paired devices again
      await showSystemDevices();

      statusMessage.value = "Disconnected from ${getDeviceName(device)}";
    } catch (e) {
      statusMessage.value =
          "Error disconnecting from ${getDeviceName(device)}: $e";
    }
  }

  Future<void> sendTestMessage(flutter_blue.BluetoothDevice device) async {
    try {
      if (!await _requestPermissions()) {
        return;
      }

      if (!device.isConnected) {
        statusMessage.value = 'Error: Device is not connected';
        return;
      }

      statusMessage.value = 'Discovering services...';
      final services = await device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            statusMessage.value =
                'Found writable characteristic. Sending test message...';

            // Send "Hello ESP32" as bytes
            List<int> data = [
              72,
              101,
              108,
              108,
              111,
              32,
              69,
              83,
              80,
              51,
              50
            ]; // "Hello ESP32"
            await characteristic.write(data,
                withoutResponse:
                    characteristic.properties.writeWithoutResponse);

            statusMessage.value = 'Test message sent successfully!';
            return;
          }
        }
      }

      statusMessage.value = 'Error: No writable characteristic found';
    } catch (e) {
      statusMessage.value = 'Error sending test message: $e';
    }
  }

  Future<void> sendBatteryInfo(flutter_blue.BluetoothDevice device,
      int currentBattery, int targetBattery) async {
    try {
      if (!await _requestPermissions()) {
        return;
      }

      if (!device.isConnected) {
        statusMessage.value = 'Error: Device is not connected';
        return;
      }

      final services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            // First send the target percentage
            List<int> targetData = targetBattery.toString().codeUnits;
            await characteristic.write(targetData,
                withoutResponse:
                    characteristic.properties.writeWithoutResponse);

            // Then send the command (up/down) based on current vs target
            List<int> command;
            if (currentBattery < targetBattery) {
              command = "up".codeUnits; // Start charging
              statusMessage.value = 'Starting charging until $targetBattery%';
            } else {
              command = "down".codeUnits; // Stop charging
              statusMessage.value = 'Stopping charging - target reached';
            }

            await Future.delayed(const Duration(
                milliseconds: 100)); // Small delay between commands
            await characteristic.write(command,
                withoutResponse:
                    characteristic.properties.writeWithoutResponse);
            return;
          }
        }
      }
      statusMessage.value = 'Error: No writable characteristic found';
    } catch (e) {
      statusMessage.value = 'Error sending battery info: $e';
    }
  }

  Future<void> updateChargingStatus(flutter_blue.BluetoothDevice device,
      int currentBattery, int targetBattery) async {
    // This method can be called periodically or when battery level changes
    if (device.isConnected) {
      await sendBatteryInfo(device, currentBattery, targetBattery);
    }
  }

  Future<void> sendZero(flutter_blue.BluetoothDevice device) async {
    try {
      await _takeMutex();
      final state = await device.connectionState.first;
      if (state != flutter_blue.BluetoothConnectionState.connected) {
        throw Exception('Device is not connected');
      }

      final services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            await characteristic.write([0], withoutResponse: false);
            update(['bluetooth_status']);
            return;
          }
        }
      }
      throw Exception('No writable characteristic found');
    } catch (e) {
      print('Error sending zero: $e');
      update(['bluetooth_status']);
    } finally {
      _giveMutex();
    }
  }

  Future<void> sendOne(flutter_blue.BluetoothDevice device) async {
    try {
      await _takeMutex();
      final state = await device.connectionState.first;
      if (state != flutter_blue.BluetoothConnectionState.connected) {
        throw Exception('Device is not connected');
      }

      final services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            await characteristic.write([1], withoutResponse: false);
            update(['bluetooth_status']);
            return;
          }
        }
      }
      throw Exception('No writable characteristic found');
    } catch (e) {
      print('Error sending one: $e');
      update(['bluetooth_status']);
    } finally {
      _giveMutex();
    }
  }

  Future<void> sendString(
      flutter_blue.BluetoothDevice device, String value) async {
    try {
      await _takeMutex();
      final state = await device.connectionState.first;
      if (state != flutter_blue.BluetoothConnectionState.connected) {
        throw Exception('Device is not connected');
      }

      final services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            await characteristic.write(value.codeUnits, withoutResponse: false);
            update(['bluetooth_status']);
            return;
          }
        }
      }
      throw Exception('No writable characteristic found');
    } catch (e) {
      print('Error sending string: $e');
      update(['bluetooth_status']);
    } finally {
      _giveMutex();
    }
  }

  // Method to check current permission status
  Future<Map<String, bool>> checkPermissionStatus() async {
    final basePermissions = {
      'bluetooth': await Permission.bluetooth.isGranted,
      'bluetoothConnect': await Permission.bluetoothConnect.isGranted,
      'bluetoothScan': await Permission.bluetoothScan.isGranted,
    };

    if (Platform.isAndroid) {
      // Android needs location permission for Bluetooth scanning
      basePermissions['location'] = await Permission.location.isGranted;
      basePermissions['backgroundLocation'] =
          await Permission.locationAlways.isGranted;
      basePermissions['notifications'] =
          await Permission.notification.isGranted;
    }

    return basePermissions;
  }

  // Method to force refresh permissions
  Future<void> refreshPermissions() async {
    statusMessage.value = "Checking permissions...";
    final hasPermissions = await _requestPermissions();
    if (hasPermissions) {
      statusMessage.value = "All permissions granted!";
      // Try to continue with Bluetooth operations
      await _initializeBluetooth();
    }
  }

  // Initialize Bluetooth after permissions are granted
  Future<void> _initializeBluetooth() async {
    try {
      // Check if Bluetooth is on, if not request to turn it on
      if (!await flutter_blue.FlutterBluePlus.isAvailable) {
        statusMessage.value = "Bluetooth is not available on this device";
        return;
      }

      if (!await flutter_blue.FlutterBluePlus.isOn) {
        statusMessage.value = "Please turn on Bluetooth";
        // Request to turn on Bluetooth
        await flutter_blue.FlutterBluePlus.turnOn();
        // Wait for Bluetooth to turn on
        await Future.delayed(const Duration(seconds: 2));
        if (!await flutter_blue.FlutterBluePlus.isOn) {
          statusMessage.value = "Failed to turn on Bluetooth";
          return;
        }
      }

      statusMessage.value =
          "Bluetooth is ready! Tap refresh to scan for devices.";
    } catch (e) {
      statusMessage.value = "Error initializing Bluetooth: $e";
    }
  }

  void closeApp() {
    // Disconnect all devices before closing
    for (var device in devices) {
      if (device.isConnected) {
        device.disconnect();
      }
    }
    // Exit the app
    exit(0);
  }
}
