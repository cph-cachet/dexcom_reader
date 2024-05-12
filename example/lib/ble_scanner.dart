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
  BluetoothDevice? latestDexcomDevice;
  PermissionStatus btePermissionStatus = PermissionStatus.denied;
  bool isScanning = false;
  bool autoScan = true;
  List<BluetoothDevice> devices = [];
  StreamSubscription<EGlucoseRxMessage>? glucoseReadingsSubscription;

  @override
  void initState() {
    super.initState();
    getLastPacket();
    _checkBluetoothPermission(); // Before using the plugin you must first have given permission to using bluetooth/Flutter blue plus.
  }

  @override
  void dispose() {
    glucoseReadingsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkBluetoothPermission() async {
    var status = await Permission.bluetooth.request();
    setState(() {
      btePermissionStatus = status;
    });
  }

  Future<void> getLastPacket() async {
    DexGlucosePacket? packet =
        await stateStorageService.getLatestDexGlucosePacket();
    if (packet != null && packet.deviceIdentifier.str.isNotEmpty) {
      setState(() {
        latestGlucosePacket = packet;
        latestDexcomDevice = BluetoothDevice(remoteId: packet.deviceIdentifier);
        devices.add(latestDexcomDevice!);
      });
    }
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
        await listenToGlucoseStream(device);
      } finally {
        setState(() => isScanning = false);
      }
    }
    setState(() => isScanning = false);
  }
  
  Future<void> subscribeToStream() async {
    while(autoScan){
      setState(() => isScanning = true);
      await dexcomReader.listenForGlucoseData(latestGlucosePacket!.deviceIdentifier.str);
      listenToGlucoseStream(latestDexcomDevice!);
      setState(() => isScanning = false);
      await Future.delayed(const Duration(seconds: 270));
    }
  }

  Future<void> listenToGlucoseStream(BluetoothDevice device) async {
    // Cancel and nullify the existing subscription if it exists
    if (glucoseReadingsSubscription != null) {
      glucoseReadingsSubscription!.cancel();
      glucoseReadingsSubscription = null;
    }
    // Delay to ensure all cleanup is done - this might be optional but can be a safe practice
    await Future.delayed(const Duration(milliseconds: 100));

    // Re-subscribe if the subscription is confirmed to be null
    glucoseReadingsSubscription =
        dexcomReader.glucoseReadings.distinct().listen(
      (reading) {
        setLatestPacket(reading, device);
      },
      onError: (error) {
        print(
            "Error listening to Stream<EGlucoseRxMessage> glucoseReadings: $error");
      },
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
      print("Saving packet: ${latestGlucosePacket.toString()}");
      stateStorageService.saveLatestDexGlucosePacket(latestGlucosePacket!);
      stateStorageService.addGlucosePacketReading(latestGlucosePacket!);
    });
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
                  scanButtonFunc: subscribeToStream),
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
