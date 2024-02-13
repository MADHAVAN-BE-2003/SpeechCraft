import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

class BluetoothController extends GetxController {
  // FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  Future scanDevices() async {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
    FlutterBluePlus.stopScan();
  }
}

Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
