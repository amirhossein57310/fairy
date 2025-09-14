import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';
import 'package:get/get.dart';
import 'package:fairy_app/controllers/bluetooth_controller.dart';

enum _TimeUnit { hours, minutes, seconds }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late final BluetoothController _bluetoothController;
  int _selectedHours = 0;
  int _selectedMinutes = 0;
  int _selectedSeconds = 0;
  DateTime? _endTime;
  _TimeUnit? _activeUnit;

  @override
  void initState() {
    super.initState();
    _bluetoothController = Get.find<BluetoothController>();
  }

  void _startTimer() {
    setState(() {
      _activeUnit = null; // Close any open picker
    });

    final totalSeconds =
        _selectedHours * 3600 + _selectedMinutes * 60 + _selectedSeconds;
    if (totalSeconds == 0) return;

    final device = _bluetoothController.lastConnectedDevice.value;
    if (device == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No device connected')),
      );
      return;
    }

    try {
      _bluetoothController.sendString(device, totalSeconds.toString());
      setState(() {
        _endTime = DateTime.now().add(Duration(seconds: totalSeconds));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    }
  }

  void _resetTimer() {
    setState(() {
      _activeUnit = null; // Close any open picker
      _endTime = null;
      _selectedHours = 0;
      _selectedMinutes = 0;
      _selectedSeconds = 0;
    });
  }

  Widget _buildTimeSegment(String label, int value, _TimeUnit unit) {
    final theme = Theme.of(context);
    final isActive = _activeUnit == unit;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeUnit = isActive ? null : unit;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value.toString().padLeft(2, '0'),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer'),
        elevation: 0,
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
              children: [
                const SizedBox(height: 40),

                // Time Display Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeSegment('H', _selectedHours, _TimeUnit.hours),
                    Text(
                      ':',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                    _buildTimeSegment('M', _selectedMinutes, _TimeUnit.minutes),
                    Text(
                      ':',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                    _buildTimeSegment('S', _selectedSeconds, _TimeUnit.seconds),
                  ],
                ),

                // Inline Picker
                if (_activeUnit != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: CupertinoPicker(
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          switch (_activeUnit) {
                            case _TimeUnit.hours:
                              _selectedHours = index;
                              break;
                            case _TimeUnit.minutes:
                              _selectedMinutes = index;
                              break;
                            case _TimeUnit.seconds:
                              _selectedSeconds = index;
                              break;
                            default:
                              break;
                          }
                        });
                      },
                      scrollController: FixedExtentScrollController(
                        initialItem: _activeUnit == _TimeUnit.hours
                            ? _selectedHours
                            : (_activeUnit == _TimeUnit.minutes
                                ? _selectedMinutes
                                : _selectedSeconds),
                      ),
                      children: List.generate(
                        _activeUnit == _TimeUnit.hours ? 24 : 60,
                        (index) => Center(
                          child: Text(
                            index.toString().padLeft(2, '0'),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Timer Countdown (when active)
                if (_endTime != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: TimerCountdown(
                      format: CountDownTimerFormat.hoursMinutesSeconds,
                      endTime: _endTime!,
                      timeTextStyle: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                      onEnd: () {
                        setState(() {
                          _endTime = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _startTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: _resetTimer,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
