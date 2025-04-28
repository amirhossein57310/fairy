import 'package:get/get.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:fairy_app/controllers/bluetooth_controller.dart';

class BatteryController extends GetxController {
  final Battery _battery = Battery();
  final RxInt currentBatteryLevel = 0.obs;
  final RxInt targetBatteryLevel = 100.obs;
  late final BluetoothController _bluetoothController;

  // Getter for battery level
  int get batteryLevel => currentBatteryLevel.value;

  @override
  void onInit() {
    super.onInit();
    _bluetoothController = Get.find<BluetoothController>();
    // Start monitoring battery level
    _startBatteryMonitoring();
  }

  @override
  void onReady() {
    super.onReady();
    // Get initial battery level immediately
    updateBatteryLevel();
  }

  // Initialize battery monitoring
  Future<void> initBattery() async {
    await updateBatteryLevel();
    _startBatteryMonitoring();
  }

  Future<void> updateBatteryLevel() async {
    try {
      final batteryLevel = await _battery.batteryLevel;

      // Only update if the level has actually changed
      if (currentBatteryLevel.value != batteryLevel) {
        currentBatteryLevel.value = batteryLevel;

        // Check if we need to update charging status
        _updateChargingStatus();
      }
    } catch (e) {
      print('Error getting battery level: $e');
    }
  }

  void _updateChargingStatus() {
    // Get all connected devices
    final connectedDevices = _bluetoothController.devices
        .where((device) => _bluetoothController.isDeviceConnected(device));

    // Update each connected device
    for (var device in connectedDevices) {
      _bluetoothController.sendBatteryInfo(
        device,
        currentBatteryLevel.value,
        targetBatteryLevel.value,
      );
    }
  }

  void _startBatteryMonitoring() {
    // Update battery level immediately
    updateBatteryLevel();

    // Listen to battery level changes
    _battery.onBatteryStateChanged.listen((BatteryState state) {
      updateBatteryLevel();
    });

    // Set up periodic updates every 10 seconds to ensure we don't miss any changes
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 10));
      await updateBatteryLevel();
      return true;
    });
  }

  void setTargetBatteryLevel(int level) {
    if (level >= 0 && level <= 100) {
      targetBatteryLevel.value = level;
      // Update charging status immediately when target changes
      _updateChargingStatus();
    }
  }

  bool shouldAllowCharging() {
    return currentBatteryLevel.value < targetBatteryLevel.value;
  }
}
