import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:day_night_time_picker/day_night_time_picker.dart';
import 'package:fairy_app/controllers/bluetooth_controller.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final BluetoothController _bluetoothController;
  Time _selectedTime = Time(hour: 8, minute: 0);
  bool _is24HourMode = true;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _bluetoothController = Get.find<BluetoothController>();
  }

  Future<void> _sendScheduleTime() async {
    final device = _bluetoothController.lastConnectedDevice.value;
    if (device == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No device connected')),
        );
      }
      return;
    }
    try {
      final timeString =
          'SCHEDULE:${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      await _bluetoothController.sendString(device, timeString);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scheduled ${_selectedTime.format(context)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  Future<void> _showTimePicker() async {
    await Navigator.of(context).push(
      showPicker(
        context: context,
        value: _selectedTime,
        onChange: (Time time) {
          setState(() {
            _selectedTime = time;
          });
        },
        is24HrFormat: _is24HourMode,
        cancelText: 'Cancel',
        okText: 'Set Time',
        hourLabel: 'Hour',
        minuteLabel: 'Minute',
        okStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        cancelStyle: TextStyle(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
    await _sendScheduleTime();
  }

  Future<void> _setScheduleEnabled(bool value) async {
    setState(() {
      _isEnabled = value;
    });
    final device = _bluetoothController.lastConnectedDevice.value;
    if (device == null) return;
    try {
      await _bluetoothController.sendString(
          device, value ? 'SCHEDULE_ENABLE' : 'SCHEDULE_DISABLE');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
                _is24HourMode ? Icons.access_time : Icons.access_time_filled),
            onPressed: () => setState(() => _is24HourMode = !_is24HourMode),
            tooltip: 'Toggle 12/24 hour format',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Time Selection Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Set Schedule Time',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Time Display
                      GestureDetector(
                        onTap: _showTimePicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _selectedTime.format(context),
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to change time',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Enable Switch (single schedule)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.power_settings_new_rounded,
                                color: _isEnabled
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Enable Schedule',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isEnabled,
                            onChanged: (value) => _setScheduleEnabled(value),
                            activeColor: theme.colorScheme.primary,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // No add button; time is sent when picker closes
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const SizedBox(height: 40),
                Icon(
                  Icons.schedule_outlined,
                  size: 64,
                  color: theme.colorScheme.outline.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Single schedule mode',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Removed multi-schedule card builder in single schedule mode
}

class ScheduleItem {
  final String id;
  final Time time;
  bool isEnabled;
  final String label;

  ScheduleItem({
    required this.id,
    required this.time,
    required this.isEnabled,
    required this.label,
  });
}
