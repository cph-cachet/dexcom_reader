import 'package:dexcom_reader_example/Pages/dex_deviceBg_listening_page.dart';
import 'package:dexcom_reader_example/StateStorage/state_storage_service.dart';
import 'package:dexcom_reader_example/models/dexdevice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class StoredDexDevicesPage extends StatefulWidget {
  const StoredDexDevicesPage({super.key});

  @override
  _StoredDexDevicesPageState createState() => _StoredDexDevicesPageState();
}

class _StoredDexDevicesPageState extends State<StoredDexDevicesPage> {
  StateStorageService stateStorageService = StateStorageService();
  List<DexDevice> _dexDevices = [];

  @override
  void initState() {
    super.initState();
    searchForDevicesIfExist();
  }

  Future<void> searchForDevicesIfExist() async {
    var list = await stateStorageService.getKnownDexDevicesIfExist();
    setState(() {
      _dexDevices = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stored Dex Devices'),
      ),
      body: _dexDevices.isEmpty
          ? Center(
              child: Container(
                width: MediaQuery.of(context).size.width - 20,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No known Dexcom devices found.',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Try and scan or add a Dexcom Device and come back later.',
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Once you have Added/Connected to a device then it will be shown here.',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'You can then view the latest glucose measurement from the stored device.',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'More glucose date can be seen by tapping on the stored device.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              itemCount: _dexDevices.length,
              itemBuilder: (context, index) {
                final dexDevice = _dexDevices[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DexDeviceBgListenPage(
                          device: BluetoothDevice(remoteId: dexDevice.remoteId),
                        ),
                      ),
                    );
                  },
                  child: ListTile(
                    title: Text("G7 Device: ${dexDevice.platformName}"),
                    subtitle: Text("BTE remoteID: ${dexDevice.remoteId.str}"),
                  ),
                );
              },
            ),
    );
  }
}
