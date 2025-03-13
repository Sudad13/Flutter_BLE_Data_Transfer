import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothOffScreen extends StatelessWidget {
  final BluetoothAdapterState adapterState;

  const BluetoothOffScreen({super.key, required this.adapterState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth is Off')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              'Bluetooth Adapter is ${adapterState.toString().split('.')[1]}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
