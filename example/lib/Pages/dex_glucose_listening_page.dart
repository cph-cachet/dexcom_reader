import 'dart:async';
import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:dexcom_reader/plugin/g7/EGlucoseRxMessage.dart';
import 'package:dexcom_reader_example/Components/bte_scanning_widget.dart';
import 'package:dexcom_reader_example/Components/dexcom_device_card.dart';
import 'package:dexcom_reader_example/StateStorage/state_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DexGlucoseListenPage extends StatefulWidget {
  const DexGlucoseListenPage({super.key});

  @override
  _DexGlucoseListenPageState createState() => _DexGlucoseListenPageState();
}

class _DexGlucoseListenPageState extends State<DexGlucoseListenPage> {
  final DexcomReader dexcomReader = DexcomReader();
  final StateStorageService stateStorageService = StateStorageService();
  DexGlucosePacket? latestGlucosePacket;
  BluetoothDevice? latestDexcomDevice;
  bool isScanning = false;
  bool autoScan = true;
  List<BluetoothDevice> devices = [];
  StreamSubscription<EGlucoseRxMessage>? glucoseReadingsSubscription;

  @override
  void initState() {
    super.initState();
    getLastPacket();
  }

  @override
  void dispose() {
    glucoseReadingsSubscription?.cancel();
    dexcomReader.disconnect();
    super.dispose();
  }

  Future<void> getLastPacket() async {
    DexGlucosePacket? packet =
        await stateStorageService.getLatestDexGlucosePacket();
    if (packet != null && packet.deviceIdentifier.str.isNotEmpty) {
      List<DexGlucosePacket>? packets = await stateStorageService
          .getGlucosePacketReadings(packet.deviceIdentifier);
      setState(() {
        latestGlucosePacket = packets.last;
        print("lastPacket: ${latestGlucosePacket!.toJson()}");
        latestDexcomDevice = BluetoothDevice(remoteId: packet.deviceIdentifier);
        devices.add(latestDexcomDevice!);
      });
    }
  }

  Future<void> subscribeToStream() async {
    print("SubscribeToStream starting connection attempts");
    if (!isScanning) {
      setState(() => isScanning = true);
      while (autoScan) {
        bool connected = false;
        while (!connected) {
          try {
            await dexcomReader
                .connectWithId(latestGlucosePacket!.deviceIdentifier.str);
            connected = true;
          } catch (e) {
            if (e.toString().contains("connection canceled") ||
                e.toString().contains("timeout")) {
              print("Connection failed: $e, retrying...");
            }
          }
        }
        if (connected) {
          glucoseReadingsSubscription?.cancel();
          glucoseReadingsSubscription =
              dexcomReader.glucoseReadings.distinct().listen(
            (reading) {
              setLatestPacket(
                  reading,
                  BluetoothDevice(
                      remoteId: latestGlucosePacket!.deviceIdentifier));
            },
          );
        }
      }
      await dexcomReader.disconnect();
    }
    await dexcomReader.disconnect();
    setState(() => isScanning = false);
  }

  void setLatestPacket(EGlucoseRxMessage reading, BluetoothDevice device) {
    final packet = DexGlucosePacket(
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
      device.remoteId,
    );

    setState(() {
      latestGlucosePacket = packet;
      print("Saving packet: ${latestGlucosePacket!.toJson()}");
      stateStorageService.saveLatestDexGlucosePacket(latestGlucosePacket!);
      stateStorageService.addGlucosePacketReading(latestGlucosePacket!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE Scanner')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(flex: 4, child: deviceListView()),
          Expanded(
            flex: 2,
            child: DexcomSubscribeToDeviceWidget(
              isScanning: isScanning,
              scanButtonFunc: subscribeToStream,
            ),
          ),
        ],
      ),
    );
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
            dexDevice: devices[index],
          );
        },
      );
    }
  }
}


/*
  Future<void> scanAndReadDevices() async {
    if (!isScanning) {
      setState(() => isScanning = true);
      try {
        BluetoothDevice? device = await dexcomReader.scanAndGetDexcomDevice();
        if (devices.any((item) => item.remoteId != device.remoteId)) {
          setState(() {
            devices.add(device);
          });
        }
        //await listenToGlucoseStream(device);
      } finally {
        setState(() => isScanning = false);
      }
    }
    setState(() => isScanning = false);
  }
 */
