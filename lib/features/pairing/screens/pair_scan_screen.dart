import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../services/bluetooth_service.dart';
import '../widgets/device_tile.dart';
import 'pair_setup_screen.dart';

class PairScanScreen extends StatefulWidget {
  const PairScanScreen({super.key});

  @override
  State<PairScanScreen> createState() =>
      _PairScanScreenState();
}

class _PairScanScreenState
    extends State<PairScanScreen> {
  final SafeBandBluetoothService bluetoothService =
    SafeBandBluetoothService();
  List<ScanResult> devices = [];

  bool scanning = true;

  @override
  void initState() {
    super.initState();
    startScan();
  }

  Future<void> startScan() async {
    setState(() {
      scanning = true;
    });

    await bluetoothService.startScan();

    bluetoothService.scanResults.listen(
  (results) {

    print("Total Devices: ${results.length}");

    for (var r in results) {
      print(
        "Device: ${r.device.platformName} "
        "RSSI: ${r.rssi}",
      );
    }

    setState(() {
      devices = results;
    });
  },
);

    await Future.delayed(
      const Duration(seconds: 5),
    );

    await bluetoothService.stopScan();

    setState(() {
      scanning = false;
    });
  }

  Future<void> connectDevice(
    BluetoothDevice device,
  ) async {
    try {
      await device.connect();

      if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      "${device.platformName} Connected Successfully",
    ),
    backgroundColor: Colors.green,
    duration: const Duration(seconds: 2),
  ),
);

await Future.delayed(
  const Duration(seconds: 2),
);

if (!mounted) return;

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => PairSetupScreen(),
  ),
);
      // NEXT STEP:
      // Save Band ID in Firestore

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Connection Failed",
          ),
        ),
      );
    }
  }

  String signalText(int rssi) {
    if (rssi > -70) {
      return "Strong Signal";
    } else if (rssi > -85) {
      return "Medium Signal";
    }
    return "Weak Signal";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
  backgroundColor: AppColors.background,
  elevation: 0,
  title: const Text(
    "Add your SafeBand",
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: () async {
        await startScan();
      },
    ),
  ],
),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              "Make sure the band is charged and nearby.",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

            CircleAvatar(
              radius: 60,
              backgroundColor:
                  Colors.white,
              child: Icon(
                Icons.watch,
                size: 60,
                color:
                    AppColors.primary,
              ),
            ),

            const SizedBox(height: 25),

            if (scanning)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text(
                    "Searching...",
                  ),
                ],
              ),

            const SizedBox(height: 20),

            const Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                "FOUND DEVICES",
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount:
                    devices.length,

                itemBuilder:
                    (context, index) {
                  final result =
                      devices[index];

                  final name =
                      result.device
                          .platformName;

                  if (name.isEmpty) {
                    return const SizedBox();
                  }

                  return DeviceTile(
                    deviceName: name,
                    signal: signalText(
                      result.rssi,
                    ),
                    onPair: () {
                      connectDevice(
                        result.device,
                      );
                    },
                  );
                },
              ),
            ),

            TextButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.keyboard,
              ),
              label: const Text(
                "Enter code manually",
              ),
            ),
          ],
        ),
      ),
    );
  }
}