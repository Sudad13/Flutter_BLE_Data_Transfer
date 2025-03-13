import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({super.key, required this.device});

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  List<BluetoothService> services = [];

  @override
  void initState() {
    super.initState();
    connectToDevice();
  }

  void connectToDevice() async {
    await widget.device.connect();
    discoverServices();
  }

  void discoverServices() async {
    List<BluetoothService> discoveredServices = await widget.device.discoverServices();
    setState(() {
      services = discoveredServices;
    });
  }

  void readCharacteristic(BluetoothCharacteristic char) async {
    List<int> value = await char.read();
    print("Read Value: $value");
  }

  void writeCharacteristic(BluetoothCharacteristic char) async {
    List<int> data = [0x01]; // Example data
    await char.write(data, withoutResponse: false);
  }

  void enableNotify(BluetoothCharacteristic char) async {
    await char.setNotifyValue(true);
    char.onValueReceived.listen((value) {
      print("Notification: $value");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.name.isNotEmpty ? widget.device.name : "Device")),
      body: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return ExpansionTile(
            title: Text('Service: ${service.uuid}'),
            children: service.characteristics.map((char) {
              return ListTile(
                title: Text('Characteristic: ${char.uuid}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () => readCharacteristic(char),
                      child: const Text("Read"),
                    ),
                    ElevatedButton(
                      onPressed: () => writeCharacteristic(char),
                      child: const Text("Write"),
                    ),
                    ElevatedButton(
                      onPressed: () => enableNotify(char),
                      child: const Text("Enable Notify"),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
