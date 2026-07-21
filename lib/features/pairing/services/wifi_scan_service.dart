import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class WifiScanService {
  static const String serviceUuid =
      "12345678-1234-1234-1234-123456789001";

  static const String wifiListUuid =
      "12345678-1234-1234-1234-123456789002";

  static const String wifiWriteUuid =
      "12345678-1234-1234-1234-123456789003";

Future<List<String>> getWifiList(
    BluetoothDevice device) async {

  List<BluetoothService> services =
      await device.discoverServices();

  print("Services Found: ${services.length}");

  for (BluetoothService service in services) {

    print("Service: ${service.uuid}");

    if (service.uuid.toString() == serviceUuid) {

      for (BluetoothCharacteristic characteristic
          in service.characteristics) {

        print("Characteristic: ${characteristic.uuid}");

        if (characteristic.uuid.toString() ==
            wifiListUuid) {

          List<int> value =
              await characteristic.read();

          print("Raw Bytes: $value");

          String wifiString =
              String.fromCharCodes(value);

          print("WiFi String:");
          print(wifiString);

          if (wifiString.trim().isEmpty) {
            return [];
          }

          return wifiString.split(",");
        }
      }
    }
  }

  return [];
}
  Future<bool> sendWifiCredentials(
  BluetoothDevice device,
  String ssid,
  String password,
) async {

  List<BluetoothService> services =
      await device.discoverServices();

  for (BluetoothService service in services) {

    if (service.uuid.toString() == serviceUuid) {

      for (BluetoothCharacteristic characteristic
          in service.characteristics) {

        if (characteristic.uuid.toString() == wifiWriteUuid) {

          String data = "$ssid|$password";

          await characteristic.write(
            data.codeUnits,
            withoutResponse: false,
          );

          print("WiFi credentials sent: $data");

          return true;
        }
      }
    }
  }

  print("Write characteristic not found");

  return false;
}
}