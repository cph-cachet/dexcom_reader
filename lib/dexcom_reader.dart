import 'dart:async';
import 'package:flutter/services.dart';
import 'package:dexcom_reader/plugin/g7/EGlucoseRxMessage.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';


enum DexcomDeviceStatus { connected, disconnected }

class DexcomReader {
  final _statusController = StreamController<DexcomDeviceStatus>.broadcast();
  final _btDevicesController =
      StreamController<List<BluetoothDevice>>.broadcast();
  final _mtuPacketsController = StreamController<List<int>>.broadcast();
  final _glucoseReadingsController =
      StreamController<EGlucoseRxMessage>.broadcast();

  Stream<DexcomDeviceStatus> get dexcomDeviceStatus => _statusController.stream;
  Stream<List<BluetoothDevice>> get deviceStream => _btDevicesController.stream;
  Stream<List<int>> get mtuPackets => _mtuPacketsController.stream;
  Stream<EGlucoseRxMessage> get glucoseReadings =>
      _glucoseReadingsController.stream;

  /// Method that scans for all nearby Dexcom Devices that are currently active
  Future<void> scanForAllDexcomDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 305));
      var sub = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          var platformName = result.device.platformName;
          if (platformName.contains('DXC') &&
              !devices.any((d) => d.platformName == platformName)) {
            print("Found a new DXC device: $platformName");
            devices.add(result.device);
            _btDevicesController.add(devices);
          }
        }
      });
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
      sub.cancel();
      FlutterBluePlus.stopScan();
    } catch (e) {
      print("Connection failed: $e, retrying connection...");
    }
  }

  /// Connect to a specific Dexcom G7 if you know its bluetooth identifier
  Future<void> connectWithId(String deviceId) async {
    final device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));
    bool isConnected = false;
    FlutterBluePlus.startScan();
    while (!isConnected) {
      try {
        print("Attempting to connect to ${device.remoteId}");
        await device.connect();
        isConnected = true;
        _statusController.add(DexcomDeviceStatus.connected);
      } catch (e) {
        print("Connection failed: $e, retrying connection...");
      }
    }

    try {
      device.mtu.listen((mtu) {});
      final services = await device.discoverServices();
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.notify ||
              characteristic.properties.indicate) {
            await subscribeToCharacteristic(characteristic);
          }
        }
      }
    } catch (e) {
      print("Error discovering services: $e");
      _statusController.add(DexcomDeviceStatus.disconnected);
      await disconnect();
    }
  }

  Future<void> subscribeToCharacteristic(
      BluetoothCharacteristic characteristic) async {
    try {
      StreamSubscription? deviceMTUSubscription;
      await characteristic.setNotifyValue(true);
      deviceMTUSubscription = characteristic.lastValueStream.distinct().listen(
        (data) {
          _mtuPacketsController.add(data);
          if (data.length == 19) {
            final streamMsg = EGlucoseRxMessage(Uint8List.fromList(data));
            _glucoseReadingsController.add(streamMsg);
          }
        },
        onError: (error) {
          print("Error on reading characteristic values: $error");
        },
      );
    } catch (e) {
      print("Error subscribing to characteristic: $e");
    } finally {
      _statusController.add(DexcomDeviceStatus.disconnected);
    }
  }

  Future<void> disconnect() async {
    try {
      _statusController.add(DexcomDeviceStatus.disconnected);
      await Future.wait([
        _statusController.close(),
        _mtuPacketsController.close(),
        _glucoseReadingsController.close(),
        _btDevicesController.close()
      ]);
    } catch (e) {
      print("Error during disconnect: $e");
    }
  }

  /// Dispose controllers
  void dispose() {
    _statusController.close();
    _btDevicesController.close();
    _mtuPacketsController.close();
    _glucoseReadingsController.close();
  }
}
