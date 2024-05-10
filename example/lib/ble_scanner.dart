import 'dart:async';
import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:dexcom_reader/plugin/g7/EGlucoseRxMessage.dart';
import 'package:dexcom_reader_example/Components/bte_scanning_widget.dart';
import 'package:dexcom_reader_example/Components/dexcom_device_card.dart';
import 'package:dexcom_reader_example/StateStorage/bluetooth_permission_service.dart';
import 'package:dexcom_reader_example/StateStorage/state_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleScanner extends StatefulWidget {
  const BleScanner({super.key});

  @override
  _BleScannerState createState() => _BleScannerState();
}

class _BleScannerState extends State<BleScanner> {
  DexcomReader dexcomReader = DexcomReader();
  StateStorageService stateStorageService = StateStorageService();
  DexGlucosePacket? latestGlucosePacket;
  PermissionStatus btePermissionStatus = PermissionStatus.denied;
  bool isScanning = false;
  List<BluetoothDevice> devices = [];
  List<DexcomDeviceCard> deviceCards = [];
  //StreamSubscription statusSubscription;

  @override
  void initState() {
    super.initState();
    BluetoothPermissionService service = BluetoothPermissionService();
    _checkBluetoothPermission(); // Before using the plugin you must first have given permission to using bluetooth/Flutter blue plus.
  }

  Future<void> _checkBluetoothPermission() async {
    var status = await Permission.bluetooth.status;
    if (status.isDenied) {
      PermissionStatus status = await Permission.bluetooth.request();
      setState(() {
        btePermissionStatus = status;
      });
    }
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('BLE Scanner'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              flex: 4,
              child: deviceListView(),
            ),
            Flexible(
              flex: 2,
              child: BTEScanningWidget(
                  isScanning: isScanning,
                  permissionStatus: btePermissionStatus,
                  scanButtonFunc: scanAndReadDevices),
            )
          ],
        ));
  }

  Widget deviceListView() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: (devices.isNotEmpty && latestGlucosePacket != null)
          ? devices.length
          : 0,
      itemBuilder: (BuildContext context, int index) {
        if (devices.isEmpty) {
          return Container(); // Acts as the replacement when there are no devices
        } else {
          return DexcomDeviceCard(
              latestGlucosePacket: latestGlucosePacket,
              dexDevice: devices[index]); // Builds a tile for each device
        }
      },
    );
  }

  Future<void> scanAndReadDevices() async {
    if (!isScanning) {
      setState(() {
        isScanning = true;
      });
      BluetoothDevice? _device = await dexcomReader.getFirstDexcomDevice();
      FlutterBluePlus.stopScan();
      setState(() {
        isScanning = false;
        devices.add(_device);
      });
      print("scanned devices $_device}");
      if (devices.isNotEmpty) {
        readDevice(_device);
      }
    } else {
      setState(() {
        isScanning = false;
      });
    }
  }

  Future<void> readDevice(BluetoothDevice device) async {
    String deviceId = devices.first.remoteId.str;
    await dexcomReader.connectWithId(
        deviceId); // Ensure connection is initiated before setting up the listener.

    StreamSubscription<DexcomDeviceStatus>? statusSubscription;
    StreamSubscription<EGlucoseRxMessage>? glucoseReadingsSubscription;

    try {
      statusSubscription = dexcomReader.status.listen(
        (event) {
          if (event == DexcomDeviceStatus.connected) {
            // Setup listener for glucose readings once connected
            glucoseReadingsSubscription =
                dexcomReader.glucoseReadings.distinct().listen(
              (reading) {
                setLatestPacket(reading, device);
                stateStorageService.getLatestDexGlucosePacket();
              },
              onError: (error) => print(
                  "Error listening to Stream<EGlucoseRxMessage> glucoseReadings: $error"),
            );
          }
        },
        onError: (error) =>
            print("Error listening to dexcom BTE device status: $error"),
      );
    } catch (e) {
      print("Error setting up device connections: $e");
    }
  }

  setLatestPacket(EGlucoseRxMessage reading, BluetoothDevice device) async {
    setState(() {
      latestGlucosePacket = DexGlucosePacket(
          reading.statusRaw,
          reading.glucoseRaw,
          reading.glucose,
          reading.clock,
          reading.timestamp,
          reading.unfiltered,
          reading.filtered,
          reading.sequence,
          reading.glucoseIsDisplayOnly,
          reading.state,
          reading.trend,
          reading.age,
          reading.valid,
          device.remoteId);
    });
  }
  // remoteID for current G7 : 2BCFED8A-09E0-BE5B-6763-EF32C6154380 , platformName DXCMWL
}
