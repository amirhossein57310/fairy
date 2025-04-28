import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bluetooth_controller.dart';
import 'bluetooth_screen.dart';
import 'schedule_screen.dart';
import 'timer_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key});

  final RxInt currentIndex = 0.obs;
  final List<Widget> screens = [
    BluetoothScreen(),
    const ScheduleScreen(),
    const TimerScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
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
          bottom: false,
          child: Obx(() => screens[currentIndex.value]),
        ),
      ),
      bottomNavigationBar: Obx(() => Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BottomNavigationBar(
                currentIndex: currentIndex.value,
                onTap: (index) => currentIndex.value = index,
                selectedItemColor: theme.colorScheme.primary,
                unselectedItemColor: Colors.grey.shade400,
                selectedFontSize: 14,
                unselectedFontSize: 12,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                items: [
                  _buildNavItem(
                    icon: Icons.battery_charging_full_rounded,
                    label: 'Charge',
                    index: 0,
                    theme: theme,
                  ),
                  _buildNavItem(
                    icon: Icons.schedule_rounded,
                    label: 'Schedule',
                    index: 1,
                    theme: theme,
                  ),
                  _buildNavItem(
                    icon: Icons.timer_rounded,
                    label: 'Timer',
                    index: 2,
                    theme: theme,
                  ),
                  _buildNavItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    index: 3,
                    theme: theme,
                  ),
                ],
              ),
            ),
          )),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required ThemeData theme,
  }) {
    final isSelected = currentIndex.value == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
          size: 24,
        ),
      ),
      activeIcon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
      ),
      label: label,
      backgroundColor: Colors.white,
    );
  }
}
