import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../services/bluetooth_service.dart';
import '../services/bluetooth_device_manager.dart';
import '../services/wifi_scan_service.dart';
import '../widgets/device_tile.dart';

/// Lets the user update an ALREADY-PAIRED band's WiFi credentials without
/// going through the full pairing flow again (which would try to
/// BandService().createBand() and fail with "already registered").
///
/// Same BLE plumbing as PairScanScreen/PairSetupScreen — just skips the
/// wearer/medical form and the Firestore band-creation step, since the
/// band already exists. [deviceId] must be the band's real `deviceId`
/// field from Firestore (the same value the ESP32 already uses as its
/// RTDB path key), NOT the Firestore document id, so it keeps writing to
/// the same RTDB node instead of a new one.
class ChangeWifiScreen extends StatefulWidget {
  final String deviceId;

  const ChangeWifiScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<ChangeWifiScreen> createState() => _ChangeWifiScreenState();
}

class _ChangeWifiScreenState extends State<ChangeWifiScreen> {
  final SafeBandBluetoothService bluetoothService =
      SafeBandBluetoothService();

  List<ScanResult> devices = [];
  bool scanning = true;

  BluetoothDevice? connectedDevice;
  bool loadingWifiList = false;
  List<String> wifiNetworks = [];
  String? selectedWifi;
  bool sending = false;

  final wifiPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    startScan();
  }

  @override
  void dispose() {
    wifiPasswordController.dispose();
    super.dispose();
  }

  Future<void> requestBlePermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> startScan() async {
    await requestBlePermissions();

    if (mounted) {
      setState(() {
        scanning = true;
        devices = [];
      });
    }

    await bluetoothService.startScan();

    bluetoothService.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          devices = results
              .where((r) => r.device.platformName.isNotEmpty)
              .toList();
        });
      }
    });

    await Future.delayed(const Duration(seconds: 5));

    await bluetoothService.stopScan();

    if (mounted) {
      setState(() {
        scanning = false;
      });
    }
  }

  Future<void> connectDevice(BluetoothDevice device) async {
    try {
      await device.connect();

      BluetoothDeviceManager.connectedDevice = device;

      if (!mounted) return;

      setState(() {
        connectedDevice = device;
        loadingWifiList = true;
      });

      final wifiList = await WifiScanService().getWifiList(device);

      if (!mounted) return;

      setState(() {
        wifiNetworks = wifiList
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();
        loadingWifiList = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection failed")),
      );
    }
  }

  Future<void> updateWifi() async {
    if (connectedDevice == null) return;

    if (selectedWifi == null || wifiPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a network and enter its password")),
      );
      return;
    }

    setState(() => sending = true);

    try {
      // Firebase email/password fields aren't used anywhere in
      // uploadVitals() — only bandId matters for the RTDB path — so they
      // can be sent empty here.
      final sent = await WifiScanService().sendWifiCredentials(
        connectedDevice!,
        selectedWifi!,
        wifiPasswordController.text.trim(),
        '',
        '',
        widget.deviceId,
      );

      if (!mounted) return;

      if (sent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("WiFi updated. Band is restarting and reconnecting..."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send new WiFi details")),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  String signalText(int rssi) {
    if (rssi > -70) return "Strong Signal";
    if (rssi > -85) return "Medium Signal";
    return "Weak Signal";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text("Change WiFi"),
        actions: connectedDevice == null
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: startScan,
                ),
              ]
            : null,
      ),
      body: connectedDevice == null
          ? _buildScanBody()
          : _buildWifiSelectBody(),
    );
  }

  Widget _buildScanBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "Make sure the band is charged and nearby, then select it below.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (scanning)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("Searching..."),
              ],
            ),
          const SizedBox(height: 10),
          Expanded(
            child: scanning
                ? const SizedBox()
                : devices.isEmpty
                    ? const Center(
                        child: Text(
                          "No devices found.\nTap refresh to scan again.",
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final result = devices[index];

                          return DeviceTile(
                            deviceName: result.device.platformName,
                            signal: signalText(result.rssi),
                            onPair: () => connectDevice(result.device),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiSelectBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Connected. Select the new WiFi network:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          if (loadingWifiList) const Center(child: CircularProgressIndicator()),

          if (!loadingWifiList)
            DropdownButtonFormField<String>(
              value: selectedWifi,
              hint: const Text("Select WiFi"),
              decoration: const InputDecoration(
                labelText: "Select WiFi",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wifi),
              ),
              items: wifiNetworks
                  .map((wifi) => DropdownMenuItem(
                        value: wifi,
                        child: Text(wifi),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => selectedWifi = value),
            ),

          const SizedBox(height: 12),

          AppTextField(
            controller: wifiPasswordController,
            obscureText: true,
            labelText: "Password",
          ),

          const SizedBox(height: 30),

          PrimaryButton(
            text: sending ? "Updating..." : "Update WiFi",
            onPressed: sending ? null : updateWifi,
          ),
        ],
      ),
    );
  }
}
