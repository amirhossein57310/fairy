import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as flutter_blue;
import '../controllers/bluetooth_controller.dart';

class BluetoothScreen extends StatelessWidget {
  final BluetoothController controller = Get.find<BluetoothController>();

  BluetoothScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paired Bluetooth Devices'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status message
                Obx(() => Text(
                      controller.statusMessage.value,
                      style: Theme.of(context).textTheme.bodyLarge,
                    )),

                const SizedBox(height: 16),

                // Show devices button
                ElevatedButton(
                  onPressed: () => controller.showSystemDevices(),
                  child: const Text('Show Paired Devices'),
                ),

                const SizedBox(height: 16),

                // Device list
                Obx(() {
                  if (controller.devices.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No paired Bluetooth devices found'),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.devices.length,
                    itemBuilder: (context, index) {
                      final device = controller.devices[index];
                      final isConnected = controller.isDeviceConnected(device);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(controller.getDeviceName(device)),
                                subtitle: Text(
                                    'MAC: ${controller.getDeviceId(device)}'),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      if (isConnected) {
                                        controller.disconnectFromDevice(device);
                                      } else {
                                        controller.connectToDevice(device);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isConnected
                                          ? Colors.red
                                          : Colors.blue,
                                    ),
                                    child: Text(
                                        isConnected ? 'Disconnect' : 'Connect'),
                                  ),
                                  if (isConnected) ...[
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () =>
                                          controller.sendTestMessage(device),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: const Text('Test Message'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
