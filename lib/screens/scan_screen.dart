import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class ScanScreen extends StatelessWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan for Devices')),
      body: RefreshIndicator(
        onRefresh: () => FlutterBluePlus.startScan(timeout: const Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(const Duration(seconds: 2))
                    .asyncMap((_) => FlutterBluePlus.connectedDevices),
                initialData: const [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map((d) => ListTile(
                    title: Text(d.platformName.isEmpty ? "Unknown" : d.platformName),
                    subtitle: Text(d.id.toString()),
                    trailing: StreamBuilder<BluetoothConnectionState>(
                      stream: d.connectionState,
                      initialData: BluetoothConnectionState.disconnected,
                      builder: (c, snapshot) {
                        if (snapshot.data == BluetoothConnectionState.connected) {
                          return const Text('CONNECTED');
                        }
                        return ElevatedButton(
                          child: const Text('CONNECT'),
                          onPressed: () => d.connect(),
                        );
                      },
                    ),
                  ))
                      .toList(),
                ),
              ),
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBluePlus.scanResults,
                initialData: const [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map((r) => ScanResultTile(
                    result: r,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          r.device.connect();
                          return DeviceScreen(device: r.device);
                        },
                      ),
                    ),
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBluePlus.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: const Icon(Icons.stop),
              onPressed: () => FlutterBluePlus.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
              child: const Icon(Icons.search),
              onPressed: () => FlutterBluePlus.startScan(timeout: const Duration(seconds: 4)),
            );
          }
        },
      ),
    );
  }
}

class ScanResultTile extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onTap;

  const ScanResultTile({Key? key, required this.result, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(result.device.platformName.isEmpty ? "Unknown" : result.device.platformName),
      subtitle: Text(result.device.id.toString()),
      trailing: ElevatedButton(child: const Text('CONNECT'), onPressed: onTap),
    );
  }
}

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  List<BluetoothService> _services = [];
  String _readValue = "No read data";
  String _writeValue = "No write data";
  String _notifyValue = "No notify data";
  Map<String, bool> _notifyStates = {};
  Map<String, StreamSubscription<List<int>>> _notificationSubscriptions = {};

  @override
  void initState() {
    super.initState();
    _setupDevice();
  }

  @override
  void dispose() {
    for (var subscription in _notificationSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _setupDevice() async {
    try {
      if (await widget.device.connectionState.first != BluetoothConnectionState.connected) {
        await widget.device.connect();
      }
      List<BluetoothService> services = await widget.device.discoverServices();
      setState(() {
        _services = services;
      });
    } catch (e) {
      print("Error connecting to device: $e");
    }
  }

  Future<void> _toggleNotification(BluetoothCharacteristic char) async {
    final uuid = char.uuid.toString();
    final currentState = _notifyStates[uuid] ?? false;
    final newState = !currentState;

    try {
      await char.setNotifyValue(newState);

      if (newState) {
        _notificationSubscriptions[uuid]?.cancel();
        _notificationSubscriptions[uuid] = char.lastValueStream.listen((value) {
          if (value.isNotEmpty) {
            setState(() {
              _notifyValue = "Notify: ${String.fromCharCodes(value)}";
            });
          }
        });
      } else {
        _notificationSubscriptions[uuid]?.cancel();
        _notificationSubscriptions.remove(uuid);
      }

      setState(() {
        _notifyStates[uuid] = newState;
      });
    } catch (e) {
      print("Error toggling notification: $e");
    }
  }

  Future<void> _showWriteDialog(BluetoothCharacteristic char) async {
    String message = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Write Message"),
          content: TextField(
            onChanged: (text) {
              message = text;
            },
            decoration: const InputDecoration(
              hintText: "Enter message to write",
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (message.isNotEmpty) {
                  try {
                    await char.write(message.codeUnits);
                    setState(() {
                      _writeValue = "Sent: $message";
                    });
                  } catch (e) {
                    print("Error writing: $e");
                  }
                }
                Navigator.pop(context);
              },
              child: const Text("Send"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.platformName.isEmpty ? "Unknown" : widget.device.platformName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(_readValue),
                Text(_writeValue),
                Text(_notifyValue),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _services.length,
              itemBuilder: (context, index) {
                BluetoothService service = _services[index];
                return ExpansionTile(
                  title: Text('Service: ${service.uuid.toString()}'),
                  children: service.characteristics.map<Widget>((char) {
                    final charId = char.uuid.toString();
                    final isNotifying = _notifyStates[charId] ?? false;

                    return ListTile(
                      title: Text('Characteristic: $charId'),
                      subtitle: Column(
                        children: [
                          Row(
                            children: [
                              if (char.properties.read)
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      var value = await char.read();
                                      setState(() {
                                        _readValue = "Read: ${String.fromCharCodes(value)}";
                                      });
                                    } catch (e) {
                                      print("Error reading: $e");
                                    }
                                  },
                                  child: const Text("Read"),
                                ),
                              if (char.properties.write)
                                ElevatedButton(
                                  onPressed: () => _showWriteDialog(char),
                                  child: const Text("Write"),
                                ),
                              if (char.properties.notify)
                                ElevatedButton(
                                  onPressed: () => _toggleNotification(char),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isNotifying ? Colors.green : null,
                                  ),
                                  child: Text(isNotifying ? "Disable Notify" : "Enable Notify"),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
