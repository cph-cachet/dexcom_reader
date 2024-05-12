import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:dexcom_reader_example/StateStorage/state_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DexcomDeviceDetailsPage extends StatefulWidget {
  final DeviceIdentifier identifier;
  const DexcomDeviceDetailsPage({super.key, required this.identifier});

  @override
  State<DexcomDeviceDetailsPage> createState() =>
      _DexcomDeviceDetailsPageState();
}

class _DexcomDeviceDetailsPageState extends State<DexcomDeviceDetailsPage> {
  TextStyle tStyle1 = GoogleFonts.roboto(
      fontSize: 20, color: Colors.black, fontWeight: FontWeight.w500);
  TextStyle tStyle2 = GoogleFonts.montserrat(
      fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500);
  StateStorageService stateStorageService = StateStorageService();
  List<DexGlucosePacket> packets = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    print("Getting data for ${widget.identifier.str}");
    List<DexGlucosePacket> r =
        await stateStorageService.getGlucosePacketReadings(widget.identifier);
    print("foundpackets: ${r.isNotEmpty}, ${r.length}");
    if (mounted) {
      setState(() {
        packets = r;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("G7 Details Page"),
            SizedBox(height: 32,),
            Expanded(
              // Use Expanded here to fill the remaining space
              child: ListView.builder(
                itemCount: packets.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: EdgeInsets.only(top: 16, left: 12, right: 16),
                    child: packetRow(packets[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget packetRow(DexGlucosePacket packet) {
    return Container(
        height: 80,
        color: Colors.grey.withOpacity(0.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Glucose: ${packet.glucose} mmol/L"),
            Text("Trend: ${packet.trend}"),
            Text("Timestamp: ${convertTimeStampToDatetime(packet.timestamp)}"),
          ],
        ));
  }

  String convertTimeStampToDatetime(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd kk:mm:ss').format(date);
  }
}
