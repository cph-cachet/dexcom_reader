import 'package:dexcom_reader_example/Pages/dex_glucose_listening_page.dart';
import 'package:dexcom_reader_example/StateStorage/state_storage_service.dart';
import 'package:dexcom_reader_example/models/dexdevice.dart';
import 'package:flutter/material.dart';

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
          ? Center(child: Text('No known Dexcom devices found.'))
          : ListView.builder(
        itemCount: _dexDevices.length,
        itemBuilder: (context, index) {
          final device = _dexDevices[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DexGlucoseListenPage(
                  ),
                ),
              );
            },
            child: ListTile(
              title: Text(device.remoteId.id),
              subtitle: Text(device.platformName),
            ),
          );
        },
      ),
    );
  }
}
