// // Copyright 2017-2023, Charles Weinberger & Paul DeMarco.
// // All rights reserved. Use of this source code is governed by a
// // BSD-style license that can be found in the LICENSE file.

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'screens/bluetooth_off_screen.dart';
// import 'screens/scan_screen.dart';

// void main() {
//   FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
//   runApp(const FlutterBlueApp());
// }

// //
// // This widget shows BluetoothOffScreen or
// // ScanScreen depending on the adapter state
// //
// class FlutterBlueApp extends StatefulWidget {
//   const FlutterBlueApp({Key? key}) : super(key: key);

//   @override
//   State<FlutterBlueApp> createState() => _FlutterBlueAppState();
// }

// class _FlutterBlueAppState extends State<FlutterBlueApp> {
//   BluetoothAdapterState _adapterState =
//       BluetoothAdapterState.unknown; //on off unknown
//   late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

//   @override
//   void initState() {
//     super.initState();
//     _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((
//       state,
//     ) {
//       _adapterState = state;
//       if (mounted) {
//         setState(() {});
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _adapterStateStateSubscription.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     Widget screen =
//         _adapterState == BluetoothAdapterState.on
//             ? const ScanScreen()
//             : BluetoothOffScreen(adapterState: _adapterState);

//     return MaterialApp(
//       color: Colors.lightBlue,
//       home: screen,
//       navigatorObservers: [BluetoothAdapterStateObserver()],
//     );
//   }
// }

// //
// // This observer listens for Bluetooth Off and dismisses the DeviceScreen
// //
// class BluetoothAdapterStateObserver extends NavigatorObserver {
//   StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

//   @override
//   void didPush(Route route, Route? previousRoute) {
//     super.didPush(route, previousRoute);
//     if (route.settings.name == '/DeviceScreen') {
//       // Start listening to Bluetooth state changes when a new route is pushed
//       _adapterStateSubscription ??= FlutterBluePlus.adapterState.listen((
//         state,
//       ) {
//         if (state != BluetoothAdapterState.on) {
//           // Pop the current route if Bluetooth is off
//           navigator?.pop();
//         }
//       });
//     }
//   }

//   @override
//   void didPop(Route route, Route? previousRoute) {
//     super.didPop(route, previousRoute);
//     // Cancel the subscription when the route is popped
//     _adapterStateSubscription?.cancel();
//     _adapterStateSubscription = null;
//   }
// }


// Copyright 2017-2023, Charles Weinberger & Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// //import 'package:newapp/main.dart';
// import 'screens/bluetooth_off_screen.dart';
// import 'screens/scan_screen.dart';
//
// void main() {
//   FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
//   runApp(const FlutterBlueApp());
// }
//
//
// // This widget shows BluetoothOffScreen or
// // ScanScreen depending on the adapter state and permissions
//
// class FlutterBlueApp extends StatefulWidget {
//   const FlutterBlueApp({Key? key}) : super(key: key);
//
//   @override
//   State<FlutterBlueApp> createState() => _FlutterBlueAppState();
// }
//
// class _FlutterBlueAppState extends State<FlutterBlueApp> {
//   BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
//   late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;
//   bool _permissionsGranted = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkAndRequestPermissions(); // Check permissions on app start
//     _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
//       _adapterState = state;
//       if (mounted) {
//         setState(() {});
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _adapterStateSubscription.cancel();
//     super.dispose();
//   }
//
//   // Check and request necessary permissions
//   Future<void> _checkAndRequestPermissions() async {
//     if (Platform.isAndroid) {
//       final androidInfo = await DeviceInfoPlugin().androidInfo;
//       final sdkInt = androidInfo.version.sdkInt;
//
//       Map<Permission, PermissionStatus> statuses;
//
//       if (sdkInt >= 31) {
//         // Android 12+ (API 31+)
//         statuses = await [
//           Permission.bluetoothScan,
//           Permission.bluetoothConnect,
//           Permission.locationWhenInUse, // Optional, depending on device
//         ].request();
//       } else {
//         // Android 6-11 (API 23-30)
//         statuses = await [
//           Permission.locationWhenInUse,
//           Permission.bluetooth, // Legacy permission
//         ].request();
//       }
//
//       // Check if all required permissions are granted
//       if (sdkInt >= 31) {
//         _permissionsGranted = statuses[Permission.bluetoothScan]!.isGranted &&
//             statuses[Permission.bluetoothConnect]!.isGranted;
//       } else {
//         _permissionsGranted = statuses[Permission.locationWhenInUse]!.isGranted;
//       }
//
//       if (!_permissionsGranted) {
//         print("Required permissions not granted");
//         // Optionally, show a dialog to inform the user
//         if (mounted) {
//           _showPermissionDeniedDialog();
//         }
//       } else {
//         print("All required permissions granted");
//         setState(() {});
//       }
//     }
//   }
//
//   // Show dialog if permissions are denied
//   void _showPermissionDeniedDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Permissions Required"),
//         content: const Text(
//           "This app requires Bluetooth and Location permissions to scan for devices. Please grant them in settings.",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               openAppSettings(); // Open app settings for manual permission granting
//             },
//             child: const Text("Open Settings"),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     Widget screen;
//
//     if (!_permissionsGranted && Platform.isAndroid) {
//       screen = Scaffold(
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text("Awaiting permissions..."),
//               ElevatedButton(
//                 onPressed: _checkAndRequestPermissions,
//                 child: const Text("Request Permissions"),
//               ),
//             ],
//           ),
//         ),
//       );
//     } else {
//       screen = _adapterState == BluetoothAdapterState.on
//           ? const ScanScreen()
//           : BluetoothOffScreen(adapterState: _adapterState);
//     }
//
//     return MaterialApp(
//       color: Colors.lightBlue,
//       home: screen,
//       navigatorObservers: [BluetoothAdapterStateObserver()],
//     );
//   }
// }
//
// //
// // This observer listens for Bluetooth Off and dismisses the DeviceScreen
// //
// class BluetoothAdapterStateObserver extends NavigatorObserver {
//   StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
//
//   @override
//   void didPush(Route route, Route? previousRoute) {
//     super.didPush(route, previousRoute);
//     if (route.settings.name == '/DeviceScreen') {
//       // Start listening to Bluetooth state changes when a new route is pushed
//       _adapterStateSubscription ??= FlutterBluePlus.adapterState.listen((state) {
//         if (state != BluetoothAdapterState.on) {
//           // Pop the current route if Bluetooth is off
//           navigator?.pop();
//         }
//       });
//     }
//   }
//
//   @override
//   void didPop(Route route, Route? previousRoute) {
//     super.didPop(route, previousRoute);
//     // Cancel the subscription when the route is popped
//     _adapterStateSubscription?.cancel();
//     _adapterStateSubscription = null;
//   }
// }

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
//import 'package:newapp/main.dart';
import 'screens/bluetooth_off_screen.dart';
import 'screens/scan_screen.dart';

void main() {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  runApp(const FlutterBlueApp());
}


// This widget shows BluetoothOffScreen or
// ScanScreen depending on the adapter state and permissions

class FlutterBlueApp extends StatefulWidget {
  const FlutterBlueApp({Key? key}) : super(key: key);

  @override
  State<FlutterBlueApp> createState() => _FlutterBlueAppState();
}

class _FlutterBlueAppState extends State<FlutterBlueApp> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions(); // Check permissions on app start
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _adapterStateSubscription.cancel();
    super.dispose();
  }

  // Check and request necessary permissions
  Future<void> _checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      Map<Permission, PermissionStatus> statuses;

      if (sdkInt >= 31) {
        // Android 12+ (API 31+)
        statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse, // Optional, depending on device
        ].request();
      } else {
        // Android 6-11 (API 23-30)
        statuses = await [
          Permission.locationWhenInUse,
          Permission.bluetooth, // Legacy permission
        ].request();
      }

      // Check if all required permissions are granted
      if (sdkInt >= 31) {
        _permissionsGranted = statuses[Permission.bluetoothScan]!.isGranted &&
            statuses[Permission.bluetoothConnect]!.isGranted;
      } else {
        _permissionsGranted = statuses[Permission.locationWhenInUse]!.isGranted;
      }

      if (!_permissionsGranted) {
        print("Required permissions not granted");
        // Optionally, show a dialog to inform the user
        if (mounted) {
          _showPermissionDeniedDialog();
        }
      } else {
        print("All required permissions granted");
        setState(() {});
      }
    }
  }

  // Show dialog if permissions are denied
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permissions Required"),
        content: const Text(
          "This app requires Bluetooth and Location permissions to scan for devices. Please grant them in settings.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // Open app settings for manual permission granting
            },
            child: const Text("Open Settings"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget screen;

    if (!_permissionsGranted && Platform.isAndroid) {
      screen = Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Awaiting permissions..."),
              ElevatedButton(
                onPressed: _checkAndRequestPermissions,
                child: const Text("Request Permissions"),
              ),
            ],
          ),
        ),
      );
    } else {
      screen = _adapterState == BluetoothAdapterState.on
          ? const ScanScreen()
          : BluetoothOffScreen(adapterState: _adapterState);
    }

    return MaterialApp(
      color: Colors.lightBlue,
      home: screen,
      navigatorObservers: [BluetoothAdapterStateObserver()],
    );
  }
}

//
// This observer listens for Bluetooth Off and dismisses the DeviceScreen
//
class BluetoothAdapterStateObserver extends NavigatorObserver {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == '/DeviceScreen') {
      // Start listening to Bluetooth state changes when a new route is pushed
      _adapterStateSubscription ??= FlutterBluePlus.adapterState.listen((state) {
        if (state != BluetoothAdapterState.on) {
          // Pop the current route if Bluetooth is off
          navigator?.pop();
        }
      });
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    // Cancel the subscription when the route is popped
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription=null;
  }
}
