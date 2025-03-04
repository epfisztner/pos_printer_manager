import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as themal;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart' as winThermal;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:pos_printer_manager/models/pos_printer.dart';
import 'package:pos_printer_manager/pos_printer_manager.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'bluetooth_service.dart';
import 'printer_manager.dart';

/// Bluetooth Printer
class BluetoothPrinterManager extends PrinterManager {
  Generator? generator;
  themal.BlueThermalPrinter bluetooth = themal.BlueThermalPrinter.instance;
  // fblue.FlutterBlue flutterBlue = fblue.FlutterBlue.instance;
  // fblue.BluetoothDevice fbdevice;

  BluetoothPrinterManager(
    POSPrinter printer,
    PaperSize paperSize,
    CapabilityProfile profile, {
    int spaceBetweenRows = 5,
    int port = 9100,
  }) {
    super.printer = printer;
    super.address = printer.address;
    super.paperSize = paperSize;
    super.profile = profile;
    super.spaceBetweenRows = spaceBetweenRows;
    super.port = port;
    generator =
        Generator(paperSize, profile, spaceBetweenRows: spaceBetweenRows);
  }

  /// [connect] let you connect to a bluetooth printer
  Future<ConnectionResponse> connect(
      {Duration? timeout = const Duration(seconds: 5)}) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        var device = themal.BluetoothDevice(printer.name, printer.address);
        await bluetooth.connect(device);
      } else if (Platform.isWindows) {
        await winThermal.PrintBluetoothThermal.connect(macPrinterAddress: printer.address!);
      }

      this.isConnected = true;
      this.printer.connected = true;
      return Future<ConnectionResponse>.value(ConnectionResponse.success);
    } catch (e) {
      this.isConnected = false;
      this.printer.connected = false;
      return Future<ConnectionResponse>.value(ConnectionResponse.timeout);
    }
  }

  /// [discover] let you explore all bluetooth printer nearby your device
  static Future<List<BluetoothPrinter>> discover() async {
    var results = await BluetoothService.findBluetoothDevice();
    return [
      ...results
          .map((e) => BluetoothPrinter(
                id: e.address,
                name: e.name,
                address: e.address,
                type: e.type,
              ))
          .toList()
    ];
  }

  /// [writeBytes] let you write raw list int data into socket
  @override
  Future<ConnectionResponse> writeBytes(List<int> data,
      {bool isDisconnect: true}) async {
    try {
      if (!isConnected) {
        await connect();
      }
      if (Platform.isAndroid || Platform.isIOS) {
        if ((await (bluetooth.isConnected as FutureOr<bool>))) {
          Uint8List message = Uint8List.fromList(data);
          PosPrinterManager.logger.warning("message.length ${message.length}");
          await bluetooth.writeBytes(message);
          if (isDisconnect) {
            await disconnect();
          }
          return ConnectionResponse.success;
        }
        return ConnectionResponse.printerNotConnected;
      } else if (Platform.isWindows) {
        final bool connectionStatus = await winThermal.PrintBluetoothThermal.connectionStatus;
        if (connectionStatus) {
          Uint8List message = Uint8List.fromList(data);
          PosPrinterManager.logger.warning("message.length ${message.length}");
          await winThermal.PrintBluetoothThermal.writeBytes(message);
          if (isDisconnect) {
            await disconnect();
          }
          return ConnectionResponse.success;
        }
        return ConnectionResponse.printerNotConnected;
      }
      return ConnectionResponse.unsupport;
    } catch (e) {
      print("Error : $e");
      return ConnectionResponse.unknown;
    }
  }

  /// [timeout]: milliseconds to wait after closing the socket
  Future<ConnectionResponse> disconnect({Duration? timeout}) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await bluetooth.disconnect();
      this.isConnected = false;
    } else if (Platform.isWindows) {
      await winThermal.PrintBluetoothThermal.disconnect;
      this.isConnected = false;
    }

    if (timeout != null) {
      await Future.delayed(timeout, () => null);
    }
    return ConnectionResponse.success;
  }
}
