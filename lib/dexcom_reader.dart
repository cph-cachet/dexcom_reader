import 'dart:async';
import 'dart:collection';
import 'package:flutter/services.dart';
import 'package:dexcom_reader/plugin/g7/EGlucoseRxMessage.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum DexcomDeviceStatus { connected, disconnected }

class DexcomReader {
  late StreamSubscription<List<int>> _deviceSubscription;

  final _statusController = StreamController<DexcomDeviceStatus>();
  final _mtuPacketsController = StreamController<List<int>>.broadcast();
  final _glucoseReadingsController = StreamController<EGlucoseRxMessage>.broadcast();

  Stream<DexcomDeviceStatus> get status => _statusController.stream;
  Stream<List<int>> get mtuPackets => _mtuPacketsController.stream;
  Stream<EGlucoseRxMessage> get glucoseReadings =>
      _glucoseReadingsController.stream;

  /// Connect to a specific Dexcom G7 if you know its bluetooth identifier
  Future<void> connectWithId(String deviceId) async {
    final device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));
    bool isConnected = false;

    while (!isConnected) {
      try {
        print("Attempting to connect to ${device.remoteId}");
        await device.connect(); // times out after 35s
        isConnected = true;
      } catch (e) {
        print("Connection failed: $e, retrying connection...");
        await Future.delayed(
            Duration(seconds: 1)); // Add a delay before retrying
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
      _statusController.add(DexcomDeviceStatus.connected);
    } catch (e) {
      print("Error discovering services: $e");
      _statusController.add(DexcomDeviceStatus.disconnected);
      await disconnect();
    }
  }

  Future<void> subscribeToCharacteristic(
      BluetoothCharacteristic characteristic) async {
    try {
      await characteristic.setNotifyValue(true);
      _deviceSubscription = characteristic.value.distinct().listen(
        (data) {
          _statusController.add(DexcomDeviceStatus.connected);
          _mtuPacketsController.add(data);
          if (data.length == 19) {
            final streamMsg = decodeGlucosePacket(Uint8List.fromList(data));
            _glucoseReadingsController.add(streamMsg);
          }
        },
        onError: (error) {
          print("Error on characteristic value: $error");
          _statusController.add(DexcomDeviceStatus.disconnected);
        },
      );
    } catch (e) {
      print("Error subscribing to characteristic: $e");
      _statusController.add(DexcomDeviceStatus.disconnected);
    }
  }

  Future<void> disconnect() async {
    try {
      _statusController.add(DexcomDeviceStatus.disconnected);
      _deviceSubscription != null ? _deviceSubscription.cancel() : null;
      await Future.wait([
        _statusController.close(),
        _mtuPacketsController.close(),
        _glucoseReadingsController.close(),
      ]);
    } catch (e) {
      print("Error during disconnect: $e");
    }
  }

  /// Method is used to scan for the nearest/first dexcom device that's active and returns it.
  /// A G7 BT device would be e.g => device.platfornName = 'DXCMHO' and device.remoteId == deviceId. Use device.remoteId of the device you wish to connect to with the method connectWithId()
  Future<BluetoothDevice> scanAndGetDexcomDevice() async {
    List<BluetoothDevice> devices = [];
    await FlutterBluePlus.startScan(
        timeout: const Duration(
            seconds:
                300)); //Scan for a select amount of time. G7's output every 300-310 seconds
    var subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.platformName.contains('DXC')) {
          devices.add(result.device);
          print("Scanned DXC Device: ${result.device.toString()}");
          FlutterBluePlus.stopScan();
          //connectWithId(result.device.remoteId.str); // This should be called by the app implementing the plugin since the device will have a positive connection state now
          return;
        }
      }
    });
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
    subscription.cancel();
    FlutterBluePlus.stopScan();
    return devices.first;
  }

  /// Method that scans for all nearby Dexcom Devices that are currently active
  /// A G7 BT device would be e.g => device.platformName = 'DXCMHO' and device.remoteId == deviceId. Use device.remoteId of the device you wish to connect to with the method connectWithId()
  Future<List<BluetoothDevice>> scanForAllDexcomDevices() async {
    List<BluetoothDevice> devices = [];
    await FlutterBluePlus.startScan(
        timeout: const Duration(
            seconds:
                330)); //Scan for a select amount of time. G7's output every 300-310 seconds
    var subscription = FlutterBluePlus.scanResults.listen((results) {
      while (devices.isEmpty) {
        for (ScanResult result in results) {
          if (result.device.platformName.contains('DXC')) {
            devices.add(result.device);
            break;
          }
        }
      }
    });
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
    subscription.cancel();
    return devices;
  }

  /// E.g [78, 0, 207, 74, 13, 0, 90, 11, 0, 1, 6, 0, 102, 0, 6, 251, 93, 0, 15] => {"statusRaw":0,"glucose":102,"clock":871119,"timestamp":1712909742781,"unfiltered":0,"filtered":0,"sequence":2906,"glucoseIsDisplayOnly":false,"state":6,"trend":-0.5,"age":6,"valid":true}
  EGlucoseRxMessage decodeGlucosePacket(Uint8List packet) {
    return EGlucoseRxMessage(packet);
  }
}
