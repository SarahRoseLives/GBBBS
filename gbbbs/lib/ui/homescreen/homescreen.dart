// ui/homescreen/homescreen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../../models/aprs_packet.dart';
import '../../tnc/benshi/radio_controller.dart';
import '../../tnc/mobilinkd/mobilinkd_controller.dart';
import '../client/client.dart';
import '../logs/logs.dart';
import '../server/server.dart';
import '../traditionalclient/traditionalclient.dart';

// Enum to manage connection state for clarity
enum ConnectionStatus { disconnected, connecting, connected }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ConnectionStatus _status = ConnectionStatus.disconnected;
  BluetoothDevice? _selectedDevice;
  dynamic _activeController; // Can hold either RadioController or MobilinkdController
  ValueNotifier<List<AprsPacket>>? _aprsPacketsNotifier;

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  /// Shows a dialog to select a bonded Bluetooth device and then connects to it.
  Future<void> _selectAndConnect() async {
    // Show device selection dialog
    final BluetoothDevice? device = await showDialog<BluetoothDevice>(
      context: context,
      builder: (context) {
        return FutureBuilder<List<BluetoothDevice>>(
          future: FlutterBluetoothSerial.instance.getBondedDevices(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SimpleDialog(
                title: Text('Searching for Devices...'),
                children: [
                  Center(
                      child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ))
                ],
              );
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return SimpleDialog(
                title: const Text('No Paired Devices Found'),
                children: [
                  const ListTile(
                    subtitle: Text(
                        'Please pair your TNC in your phone\'s Bluetooth settings first.'),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK')),
                  )
                ],
              );
            }

            return SimpleDialog(
              title: const Text('Choose Bluetooth TNC'),
              children: snapshot.data!.map((device) {
                return SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, device);
                  },
                  child: Text(
                      '${device.name ?? 'Unknown Device'} (${device.address})'),
                );
              }).toList(),
            );
          },
        );
      },
    );

    if (device == null) return; // User cancelled the dialog

    setState(() {
      _status = ConnectionStatus.connecting;
      _selectedDevice = device;
      // Disconnect any previous connection before starting a new one
      _activeController?.dispose();
      _activeController = null;
      _aprsPacketsNotifier = null;
    });

    try {
      final deviceName = device.name ?? '';
      dynamic controller;
      // Identify the device and initialize the appropriate controller
      if (deviceName.contains('Mobilinkd TNC')) {
        debugPrint(
            'Device identified as Mobilinkd. Initializing MobilinkdController...');
        controller = MobilinkdController(device: device);
        await controller.connect();
        _aprsPacketsNotifier = controller.aprsPackets;
      } else if (deviceName.contains('VR-N76')) {
        debugPrint(
            'Device identified as Benshi (VR-N76). Initializing RadioController...');
        controller = RadioController(device: device);
        await controller.connect();
        _aprsPacketsNotifier = controller.aprsPackets;
      } else {
        throw Exception('Unsupported device: $deviceName');
      }

      setState(() {
        _activeController = controller;
        _status = ConnectionStatus.connected;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully connected to ${device.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Connection failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _disconnect(); // Reset state on failure
    }
  }

  /// Disconnects from the active device and resets the UI state.
  void _disconnect() {
    _activeController?.dispose();
    setState(() {
      _status = ConnectionStatus.disconnected;
      _selectedDevice = null;
      _activeController = null;
      _aprsPacketsNotifier = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Branding header
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(Icons.waves,
                    size: 72, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  'Go-Box BBS',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A Modern BBS in a Box',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildStatusCard(),
          const SizedBox(height: 16),

          // Main content area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  /// Builds the main content area with navigation buttons in a grid.
  Widget _buildContent() {
    final bool isConnected = _status == ConnectionStatus.connected;

    // Helper to create a styled grid button
    Widget buildGridButton(
        String title, IconData icon, VoidCallback? onPressed) {
      return Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(icon,
                  size: 48,
                  color: isConnected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    void showDisconnectedToast() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect to a TNC first.'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          buildGridButton(
            'Client',
            Icons.chat_bubble_outline,
            isConnected
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ClientScreen(tncController: _activeController!)))
                : showDisconnectedToast,
          ),
          buildGridButton(
            'Logs',
            Icons.history,
            isConnected && _aprsPacketsNotifier != null
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LogsScreen(
                            aprsPacketsNotifier: _aprsPacketsNotifier!)))
                : showDisconnectedToast,
          ),
          buildGridButton(
            'Server',
            Icons.dns_outlined,
            isConnected
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ServerScreen(tncController: _activeController!)))
                : showDisconnectedToast,
          ),
          buildGridButton(
            'Traditional Client',
            Icons.terminal,
            isConnected
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TraditionalClientScreen()))
                : showDisconnectedToast,
          ),
        ],
      ),
    );
  }

  /// Builds the TNC status card based on the current connection state.
  Widget _buildStatusCard() {
    String subtitle;
    Icon leadingIcon;
    Widget trailingButton;

    switch (_status) {
      case ConnectionStatus.disconnected:
        subtitle = 'Disconnected';
        leadingIcon = const Icon(Icons.bluetooth_disabled, color: Colors.grey);
        trailingButton = ElevatedButton.icon(
          icon: const Icon(Icons.power_settings_new),
          label: const Text('Connect'),
          onPressed: _selectAndConnect,
        );
        break;
      case ConnectionStatus.connecting:
        subtitle = 'Connecting to ${_selectedDevice?.name ?? '...'}';
        leadingIcon =
            const Icon(Icons.bluetooth_searching, color: Colors.orange);
        trailingButton = const ElevatedButton(
          onPressed: null,
          child: SizedBox(
            height: 20,
            width: 20,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        );
        break;
      case ConnectionStatus.connected:
        subtitle = 'Connected to ${_selectedDevice?.name ?? 'device'}';
        leadingIcon = Icon(Icons.bluetooth_connected,
            color: Theme.of(context).primaryColor);
        trailingButton = ElevatedButton.icon(
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Disconnect'),
          onPressed: _disconnect,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
        );
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: leadingIcon,
        title: const Text('TNC Status:'),
        subtitle: Text(subtitle),
        trailing: trailingButton,
      ),
    );
  }
}