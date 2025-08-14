import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:battery_plus/battery_plus.dart';

class BackgroundService {
  static bool _isServiceRunning = false;
  static Timer? _timer;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'fairy_service',
        initialNotificationTitle: 'Fairy Service',
        initialNotificationContent: 'در حال اجرا...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    // iOS background processing is limited
    // This method is called when the app goes to background
    // Return true to keep the service alive
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    final battery = Battery();
    _isServiceRunning = true;

    if (service is AndroidServiceInstance) {
      // Android-specific service handling
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });

      service.on('stopService').listen((event) async {
        _isServiceRunning = false;
        _timer?.cancel();
        await service.stopSelf();
      });

      _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        if (!_isServiceRunning) {
          timer.cancel();
          return;
        }

        final batteryLevel = await battery.batteryLevel;
        service.setForegroundNotificationInfo(
          title: "Fairy Service",
          content: "سطح باتری: $batteryLevel٪",
        );

        service.invoke('update', {
          'battery_level': batteryLevel,
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
    } else {
      // iOS service handling (limited background execution)
      service.on('stopService').listen((event) async {
        _isServiceRunning = false;
        _timer?.cancel();
      });

      // iOS background services are more limited
      // We can still monitor battery but with restrictions
      _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        if (!_isServiceRunning) {
          timer.cancel();
          return;
        }

        try {
          final batteryLevel = await battery.batteryLevel;
          service.invoke('update', {
            'battery_level': batteryLevel,
            'timestamp': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          // Handle errors gracefully on iOS
          print('Background service error on iOS: $e');
        }
      });
    }
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }
}
