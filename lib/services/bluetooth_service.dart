import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as thermal;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart' as winThermal;
import '../pos_printer_manager.dart';

class BluetoothService {
  static Future<List<BluetoothPrinter>> findBluetoothDevice() async {
    List<BluetoothPrinter> devices = [];
    if (Platform.isAndroid || Platform.isIOS) {
      thermal.BlueThermalPrinter bluetooth =
          thermal.BlueThermalPrinter.instance;

      var results = await bluetooth.getBondedDevices();
      devices = results
          .map(
            (d) => BluetoothPrinter(
              id: d.address,
              address: d.address,
              name: d.name,
              type: d.type,
            ),
          )
          .toList();
    } else if (Platform.isWindows) {
      final List<winThermal.BluetoothInfo> listResult = await winThermal.PrintBluetoothThermal.pairedBluetooths;

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
