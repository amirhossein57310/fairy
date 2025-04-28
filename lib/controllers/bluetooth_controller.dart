import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as flutter_blue;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';

class BluetoothController extends GetxController {
  final RxList<flutter_blue.BluetoothDevice> devices =
      <flutter_blue.BluetoothDevice>[].obs;
  final RxString statusMessage = ''.obs;

  bool _isLocked = false;
  Completer<void>? _lock;

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
    if (await Permission.bluetoothConnect.request().isGranted) {
      return true;
    }
    statusMessage.value = "Bluetooth permissions are required";
    return false;
  }

  Future<void> showSystemDevices() async {
    try {
      // Request permissions first
      if (!await _requestPermissions()) {
        return;
      }

      // Clear previous devices
      devices.clear();
      statusMessage.value = "Getting paired devices...";

      // Get paired devices from system
      List<flutter_blue.BluetoothDevice> pairedDevices =
          await flutter_blue.FlutterBluePlus.bondedDevices;

      // Add found devices to the list
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
      // Request permissions first
      if (!await _requestPermissions()) {
        return;
      }

      statusMessage.value = "Connecting to ${getDeviceName(device)}...";

      // Connect to the device
      await device.connect();

      // Discover services after connection
      statusMessage.value = "Discovering services...";
      await device.discoverServices();

      statusMessage.value = "Connected to ${getDeviceName(device)}";
    } catch (e) {
      statusMessage.value = "Error connecting to ${getDeviceName(device)}: $e";
    }
  }

  Future<void> disconnectFromDevice(flutter_blue.BluetoothDevice device) async {
    try {
      // Request permissions first
      if (!await _requestPermissions()) {
        return;
      }

      statusMessage.value = "Disconnecting from ${getDeviceName(device)}...";

      // Disconnect from the device
      await device.disconnect();

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

  @override
  void onInit() async {
    super.onInit();
    // Request permissions first
    if (await _requestPermissions()) {
      // Try to enable Bluetooth if it's off
      if (!await flutter_blue.FlutterBluePlus.isOn) {
        try {
          await flutter_blue.FlutterBluePlus.turnOn();
        } catch (e) {
          statusMessage.value = 'Please enable Bluetooth manually';
        }
      }
      // Start scanning after permissions and Bluetooth check
      showSystemDevices();
    }
  }
}
