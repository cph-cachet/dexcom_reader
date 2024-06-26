import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:dexcom_reader_example/Components/dexcom_device_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class DexcomDeviceCard extends StatelessWidget {
  final DexGlucosePacket? latestGlucosePacket;
  final BluetoothDevice dexDevice;
  const DexcomDeviceCard(
      {super.key, required this.latestGlucosePacket, required this.dexDevice});

  @override
  Widget build(BuildContext context) {
    BoxShadow bshadow1 = BoxShadow(
      color: Colors.grey.withOpacity(0.5),
      blurRadius: 2,
      spreadRadius: 1,
      offset: const Offset(3, 3),
    );
    TextStyle tStyle1 = GoogleFonts.roboto(
        fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500);
    TextStyle tStyle2 = GoogleFonts.montserrat(
        fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500);
    Radius radius = const Radius.circular(32.0);
    return InkWell(
      onTap: () async {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DexcomDeviceDetailsPage(
                      identifier: dexDevice.remoteId,
                    )));
      },
      child: Padding(
          padding:
              const EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 16),
          child: Container(
            decoration: BoxDecoration(
                boxShadow: [
                  bshadow1,
                ],
                color: Colors.lightGreenAccent.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                    topLeft: radius, bottomLeft: radius, topRight: radius)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.only(
                        left: 12.0, top: 18.0, bottom: 18.0),
                    child: Text(
                      "Device: ${dexDevice.platformName.isEmpty ? dexDevice.remoteId : dexDevice.platformName}",
                      style: GoogleFonts.roboto(
                          fontSize: dexDevice.platformName.isEmpty ? 16 : 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(
                      left: 12.0, top: 18.0, bottom: 18.0),
                  child: Text(
                    "Glucose: ${latestGlucosePacket != null ? latestGlucosePacket!.glucose : ""} mmol/L",
                    style: tStyle1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(
                      left: 12.0, top: 12.0, bottom: 12.0),
                  child: Text(
                    latestGlucosePacket != null
                        ? "Trend: ${latestGlucosePacket!.trend}"
                        : "No trend data",
                    maxLines: 2,
                    style: tStyle2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(
                      left: 12.0, top: 12.0, bottom: 18.0),
                  child: Text(
                    latestGlucosePacket != null
                        ? "Timestamp: ${convertTimeStampToDatetime(latestGlucosePacket!.timestamp)}"
                        : "No timestamp data",
                    maxLines: 2,
                    style: tStyle2,
                  ),
                ),
              ],
            ),
          )),
    );
  }

  String convertTimeStampToDatetime(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd kk:mm:ss').format(date);
  }
}
