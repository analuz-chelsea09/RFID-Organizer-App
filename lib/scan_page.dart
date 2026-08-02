import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_constants.dart';

// This is the app's BLE "pairing" entry point (drawer -> Scan Devices).
// It looks specifically for the mc's advertised name ("RFID_Reader"),
// connects to it, and reports the connected device back up to
// MainScreen via widget.onConnected so the rest of the app (NfcScanCard
// etc.) can use it.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.onConnected});
  final ValueChanged<BluetoothDevice> onConnected;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  static const _targetDeviceName = 'RFID_Reader';

  bool _isScanning = false;
  bool _isConnecting = false;
  BluetoothDevice? _connectedDevice;
  String? _statusMessage;

  StreamSubscription<List<ScanResult>>? _scanResultsSub;

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning for $_targetDeviceName...';
    });

    await _scanResultsSub?.cancel();
    _scanResultsSub = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        if (result.device.platformName == _targetDeviceName) {
          _connectTo(result.device);
          break;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 8),
        withServices: [Guid(serviceUuid)],
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _statusMessage = 'Scan failed: $e';
      });
      return;
    }

    // startScan's future completes when the timeout elapses (or stopScan
    // is called). If we're still "scanning" at that point, nothing was
    // found in time.
    if (mounted && _isScanning && _connectedDevice == null) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'No $_targetDeviceName found nearby. Try again.';
      });
    }
  }

  Future<void> _connectTo(BluetoothDevice device) async {
    if (_isConnecting || _connectedDevice != null) return;

    setState(() {
      _isConnecting = true;
      _statusMessage = 'Found $_targetDeviceName, connecting...';
    });

    await FlutterBluePlus.stopScan();
    await _scanResultsSub?.cancel();

    try {
      await device.connect(timeout: const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _connectedDevice = device;
        _isScanning = false;
        _isConnecting = false;
        _statusMessage = 'Connected to $_targetDeviceName.';
      });
      widget.onConnected(device);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _isScanning = false;
        _statusMessage = 'Failed to connect: $e';
      });
    }
  }

  @override
  void dispose() {
    _scanResultsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isScanning || _isConnecting;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _connectedDevice != null
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_searching,
                size: 48,
                color: _connectedDevice != null
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: busy ? null : _startScan,
                child: Text(
                  _isConnecting
                      ? 'Connecting...'
                      : _isScanning
                          ? 'Scanning...'
                          : _connectedDevice != null
                              ? 'Reconnect'
                              : 'Scan for RFID Reader',
                ),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                Text(_statusMessage!, textAlign: TextAlign.center),
              ],
              if (_connectedDevice != null) ...[
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
