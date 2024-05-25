import 'dart:async';
import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:dexcom_reader/plugin/g7/EGlucoseRxMessage.dart';
import 'package:dexcom_reader_example/Components/bte_scanning_widget.dart';
import 'package:dexcom_reader_example/Components/dexcom_device_card.dart';
import 'package:dexcom_reader_example/StateStorage/state_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DexDeviceBgListenPage extends StatefulWidget {
  final BluetoothDevice device;
  const DexDeviceBgListenPage({super.key, required this.device});

  @override
  _DexDeviceBgListenPageState createState() => _DexDeviceBgListenPageState();
}

class _DexDeviceBgListenPageState extends State<DexDeviceBgListenPage> {
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
    devices.add(widget.device);
    getLastPacket();
  }

  @override
  void dispose() {
    cancelSubscription();
    dexcomReader.dispose();
    super.dispose();
  }

  void cancelSubscription() {
    glucoseReadingsSubscription?.cancel();
    glucoseReadingsSubscription = null;
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
          // Cancel any existing subscription before starting a new one
          cancelSubscription();
          await Future.delayed(Duration(milliseconds: 50));
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
      setState(() => isScanning = false);
      print("Just unsubbed and will scan sub again: $autoScan");
      if(autoScan) subscribeToStream();
    }
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
      appBar: AppBar(title: Text('G7 ${widget.device.platformName}')),
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
      return DexcomDeviceCard(
        latestGlucosePacket: latestGlucosePacket,
        dexDevice: devices.first,
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
