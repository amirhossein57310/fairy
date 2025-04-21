import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as flutter_blue;
import 'package:permission_handler/permission_handler.dart';

class BluetoothController extends GetxController {
  final RxList<flutter_blue.BluetoothDevice> devices =
      <flutter_blue.BluetoothDevice>[].obs;
  final RxString statusMessage = ''.obs;

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

  Future<void> sendZero(flutter_blue.BluetoothDevice device) async {
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
            await characteristic.write([0],
                withoutResponse:
                    characteristic.properties.writeWithoutResponse);
            statusMessage.value = 'Sent 0 to ${getDeviceName(device)}';
            return;
          }
        }
      }
      statusMessage.value = 'Error: No writable characteristic found';
    } catch (e) {
      statusMessage.value = 'Error sending data: $e';
    }
  }

  Future<void> sendOne(flutter_blue.BluetoothDevice device) async {
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
            await characteristic.write([1],
                withoutResponse:
                    characteristic.properties.writeWithoutResponse);
            statusMessage.value = 'Sent 1 to ${getDeviceName(device)}';
            return;
          }
        }
      }
      statusMessage.value = 'Error: No writable characteristic found';
    } catch (e) {
      statusMessage.value = 'Error sending data: $e';
    }
  }
}
