import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:dexcom_reader_example/StateStorage/state_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DexcomDeviceDetailsPage extends StatefulWidget {
  DeviceIdentifier identifier;
  const DexcomDeviceDetailsPage({super.key, required this.identifier});

  @override
  State<DexcomDeviceDetailsPage> createState() => _DexcomDeviceDetailsPageState();
}

class _DexcomDeviceDetailsPageState extends State<DexcomDeviceDetailsPage> {
  BoxShadow bshadow1 = BoxShadow(
    color: Colors.grey.withOpacity(0.5),
    blurRadius: 2,
    spreadRadius: 1,
    offset: const Offset(3, 3),
  );
  TextStyle tStyle1 = GoogleFonts.roboto(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500);
  TextStyle tStyle2 = GoogleFonts.montserrat(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500);

  final DexcomReader _dexcomReader = DexcomReader();
  Radius _radius = const Radius.circular(32.0);
  StateStorageService stateStorageService = StateStorageService();
  late List<DexGlucosePacket> packets;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  loadData() async {
    List<DexGlucosePacket> r = await stateStorageService.getGlucosePacketReadings(widget.identifier);
    print("foundpackets: ${r.isNotEmpty}, ${r.length}");
    setState(() {
      packets = r;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
            padding: const EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                  boxShadow: [
                    bshadow1,
                  ],
                  color: Colors.lightGreenAccent.withOpacity(0.5),
                  borderRadius: BorderRadius.only(
                      topLeft: _radius, bottomLeft: _radius, topRight: _radius)),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: packets.length,
                itemBuilder: (BuildContext context, int index) {
                  return packetRow(packets[index]);
                },
              ),
            )),
      ),
    );
  }
  
  Widget packetRow(DexGlucosePacket packet){
    return Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Row(
      children: [  Container(
        padding: const EdgeInsets.only(left: 12.0, top: 18.0, bottom: 18.0),
        child: Text(
          "Glucose: ${packet.glucose} mmol/L",
          style: tStyle1,
        ),
      ),
        Container(
          padding: const EdgeInsets.only(left: 12.0, top: 12.0, bottom: 12.0),
          child: Text(
            "Trend: ${packet.trend}",
            maxLines: 2,
            style: tStyle2,
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 12.0, top: 12.0, bottom: 18.0),
          child: Text("Timestamp: ${convertTimeStampToDatetime(packet.timestamp)}",
            maxLines: 2,
            style: tStyle2,
          ),
        )],
    ),);
  }
  String convertTimeStampToDatetime(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd kk:mm:ss').format(date);
  }
}
