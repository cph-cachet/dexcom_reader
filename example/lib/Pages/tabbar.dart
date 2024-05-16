import 'package:dexcom_reader_example/StateStorage/bluetooth_permission_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dex_device_scanning_page.dart';
import 'stored_dex_devices_page.dart';

class TabbarPage extends StatefulWidget {
  const TabbarPage({super.key});

  @override
  _TabbarPageState createState() => _TabbarPageState();
}

class _TabbarPageState extends State<TabbarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PermissionStatus btePermissionStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkBluetoothPermission();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkBluetoothPermission() async {
    var status = await Permission.bluetooth.request();
    setState(() {
      btePermissionStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dexcom Reader plugin example app'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Scan/Add Devices'),
            Tab(icon: Icon(Icons.devices), text: 'Saved Devices'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DexDeviceScanningPage(),
          StoredDexDevicesPage(),
        ],
      ),
    );
  }
}
