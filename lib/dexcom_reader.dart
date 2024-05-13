import 'dart:async';
import 'dart:collection';
import 'package:flutter/services.dart';
import 'package:dexcom_reader/plugin/g7/EGlucoseRxMessage.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum DexcomDeviceStatus { connected, disconnected }

class DexcomReader {
  late StreamSubscription _deviceSubscription;

  final _statusController = StreamController<DexcomDeviceStatus>();
  Stream<DexcomDeviceStatus> get status => _statusController.stream;

  final _glucoseReadingsController =
      StreamController<EGlucoseRxMessage>.broadcast();
  Stream<EGlucoseRxMessage> get glucoseReadings =>
      _glucoseReadingsController.stream;

  final _mtuPacketsController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get mtuPackets => _mtuPacketsController.stream;

  /// Method is used to extract the BT names and device identifiers out of all nearby dexcom devices
  /// A G7 BT device would be e.g => device.platfornName = 'DXCMHO' and device.remoteId == deviceId. Use device.remoteId of the device you wish to connect to with the method connectWithId()
  Future<BluetoothDevice> getFirstDexcomDevice() async {
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

  /// Method is used to extract the BT names and device identifiers out of all nearby dexcom devices
  /// A G7 BT device would be e.g => device.platfornName = 'DXCMHO' and device.remoteId == deviceId. Use device.remoteId of the device you wish to connect to with the method connectWithId()
  Future<List<BluetoothDevice>> getScannedDexcomDevices() async {
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

  /// Connect to a specific Dexcom G7 if you know its bluetooth identifier
  Future<void> connectWithId(String deviceId) async {
    BluetoothDevice device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));

    // Retry connection indefinitely until successful since device is
    bool isConnected = false;
    while (!isConnected) {
      try {
        print("Attempting to connect to ${device.remoteId}");
        await device.connect().timeout(Duration(seconds: 300));
        isConnected = true;  // Update flag on successful connection
      } catch (e) {

        print("Connection failed: $e");
        print("Retrying connection...");
        if(e == "FlutterBluePlusException | connect | fbp-code: 10 | connection canceled"){
          print("trueee lmao");
        }
      }
    }

    // Connection has been established, proceed with service/message discovery
    device.mtu.listen((mtu) {});
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify ||
            characteristic.properties.indicate) { // G7 Notifies when it releases from hold and sends sample
          await characteristic.setNotifyValue(true);
          _deviceSubscription =
              characteristic.onValueReceived.distinct().listen((data) {
                _statusController.add(DexcomDeviceStatus.connected);
                _mtuPacketsController.add(data);
                if (data.length == 19) {
                  EGlucoseRxMessage streamMsg =
                  decodeGlucosePacket(Uint8List.fromList(data));
                  _glucoseReadingsController.add(streamMsg);
                }
              });
        }
      }
    }
    _statusController.add(DexcomDeviceStatus.disconnected);
  }


  Future<void> listenForGlucoseData(String deviceId) async {
    BluetoothDevice device =
        BluetoothDevice(remoteId: DeviceIdentifier(deviceId));
    print("Attempting to connect to ${device.remoteId}");
    await device
        .connect()
        .onError((error, stackTrace) => (){
          print("FlutterBluePlus timed out... Will connect again");
      listenForGlucoseData(deviceId);
    });
    device.mtu.listen((mtu) {});
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify ||
            characteristic.properties.indicate) {
          await characteristic.setNotifyValue(true);
          _deviceSubscription =
              characteristic.onValueReceived.distinct().listen((data) {
            _statusController.add(DexcomDeviceStatus.connected);
            if (data.length == 19) {
              EGlucoseRxMessage streamMsg =
                  decodeGlucosePacket(Uint8List.fromList(data));
              _glucoseReadingsController.add(streamMsg);
            }
          });
        }
      }
    }
  }

  Future<void> disconnect() async {
    await _deviceSubscription.cancel();
    _statusController.add(DexcomDeviceStatus.disconnected);
  }

  /// E.g [78, 0, 207, 74, 13, 0, 90, 11, 0, 1, 6, 0, 102, 0, 6, 251, 93, 0, 15] => {"statusRaw":0,"glucose":102,"clock":871119,"timestamp":1712909742781,"unfiltered":0,"filtered":0,"sequence":2906,"glucoseIsDisplayOnly":false,"state":6,"trend":-0.5,"age":6,"valid":true}
  EGlucoseRxMessage decodeGlucosePacket(Uint8List packet) {
    return EGlucoseRxMessage(packet);
  }
}
