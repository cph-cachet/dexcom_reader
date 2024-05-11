import 'dart:async';
import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:dexcom_reader/plugin/g7/EGlucoseRxMessage.dart';
import 'package:dexcom_reader_example/Components/bte_scanning_widget.dart';
import 'package:dexcom_reader_example/Components/dexcom_device_card.dart';
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
  bool autoScan = true;
  List<BluetoothDevice> devices = [];
  List<DexcomDeviceCard> deviceCards = [];
  StreamSubscription<EGlucoseRxMessage>? glucoseReadingsSubscription;

  @override
  void initState() {
    super.initState();
    getLastPacket();
    _checkBluetoothPermission(); // Before using the plugin you must first have given permission to using bluetooth/Flutter blue plus.
  }

  Future<void> _checkBluetoothPermission() async {
    var status = await Permission.bluetooth.request();
    setState(() {
      btePermissionStatus = status;
    });
  }

  Future<void> getLastPacket() async {
    DexGlucosePacket? packet = await stateStorageService.getLatestDexGlucosePacket();
    if(packet != null && packet.deviceIdentifier.str.isNotEmpty){
      setState(() {
        latestGlucosePacket = packet;
        devices.add(BluetoothDevice(remoteId: packet.deviceIdentifier));
      });
    }
  }

  @override
  void dispose() {
    glucoseReadingsSubscription?.cancel();
    super.dispose();
  }

  Future<void> scanAndReadDevices() async {
    if (!isScanning) {
      setState(() => isScanning = true);
      try {
        BluetoothDevice? device = await dexcomReader.getFirstDexcomDevice();
        if (devices.any((item) => item.remoteId != device.remoteId)) {
          setState(() {
            devices.add(device);
          });
        }
        print("Scanned device $device");
        //await readDevice(device);
        await listenToGlucoseStream(device);
      } finally {
        setState(() => isScanning = false);
      }
    }
    setState(() => isScanning = false);
  }

  Future<void> listenToGlucoseStream(BluetoothDevice device) async {
    await glucoseReadingsSubscription?.cancel();
    glucoseReadingsSubscription = dexcomReader.glucoseReadings.distinct().listen(
      (reading) {
        setLatestPacket(reading, device);
      },
      onError: (error) => print("Error listening to Stream<EGlucoseRxMessage> glucoseReadings: $error"),
    );
  }

  // remoteID for current G7 : 2BCFED8A-09E0-BE5B-6763-EF32C6154380 , platformName #1 DXCMHO #2 DXCMWL
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
    stateStorageService.saveLatestDexGlucosePacket(latestGlucosePacket!);
    if(autoScan){
      glucoseReadingsSubscription?.cancel();
      listenToGlucoseStream(devices.first);
    }
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
            Expanded(
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
    if (devices.isEmpty) {
      return Center(child: Text("No devices found"));
    } else {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: devices.length,
        itemBuilder: (BuildContext context, int index) {
          return DexcomDeviceCard(
              latestGlucosePacket: latestGlucosePacket,
              dexDevice: devices[index]);
        },
      );
    }
  }
}