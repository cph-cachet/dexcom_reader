# dexcom_g7_reader

This is the dexcom_reader plugin

## Getting Started

To start using dexcom_reader, initialise the plugin class :

DexcomReader reader = DexcomReader();

## Scanning for a device

Before data can be read from a Dexcom G7, please use the DexcomReader method scanForAllDexcomDevices() to search for any nearby active devices.

Once a device or devices have been found, you can extract the BluetoothDevice.remoteId and use to connect and read glucose messages.

## Reading messages

Use DexcomReader.connectWithId() once you have a CGM remoteId. It will then listen for incoming messages
