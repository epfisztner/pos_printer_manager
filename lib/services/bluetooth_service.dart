import 'dart:io';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../pos_printer_manager.dart';

class BluetoothService {
  static Future<List<BluetoothPrinter>> findBluetoothDevice() async {
    List<BluetoothPrinter> devices = [];
    if (Platform.isAndroid || Platform.isIOS || Platform.isWindows) {
      final List<BluetoothInfo> listResult = await PrintBluetoothThermal.pairedBluetooths;

      devices = listResult
          .map(
            (d) => BluetoothPrinter(
          id: d.macAdress,
          address: d.macAdress,
          name: d.name,
          type: 0,
        ),
      )
          .toList();
    }
    return devices;
  }
}
