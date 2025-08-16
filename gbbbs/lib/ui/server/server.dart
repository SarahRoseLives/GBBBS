import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/bbs_packet.dart';

class ServerScreen extends StatefulWidget {
  final dynamic tncController;
  const ServerScreen({super.key, required this.tncController});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  bool _serverRunning = false;
  StreamSubscription? _bbsSubscription;
  final _callsignController = TextEditingController(text: "BBS-1");
  final List<String> _logMessages = [];
  final Set<String> _connectedClients = {};

  @override
  void dispose() {
    _bbsSubscription?.cancel();
    _callsignController.dispose();
    super.dispose();
  }

  void _log(String message) {
    if (!mounted) return;
    setState(() {
      _logMessages.insert(0, "${TimeOfDay.now().format(context)} - $message");
    });
  }

  void _toggleServer() {
    setState(() {
      _serverRunning = !_serverRunning;
    });

    if (_serverRunning) {
      final callsign = _callsignController.text.trim().toUpperCase();
      if (callsign.isEmpty) {
        _log("Error: Callsign cannot be empty.");
        setState(() => _serverRunning = false);
        return;
      }
      widget.tncController.userCallsign = callsign;
      _log("Server started with callsign $callsign. Listening for connections...");
      _listenForPackets();
    } else {
      _log("Server stopped.");
      _bbsSubscription?.cancel();
      setState(() {
        _connectedClients.clear();
      });
    }
  }

  void _listenForPackets() {
    _bbsSubscription?.cancel(); // Ensure only one listener is active
    _bbsSubscription = widget.tncController.bbsPacketStream.listen((packet) {
      if (!mounted) return;
      if (packet.info == ">CONNECT<") {
        _handleConnectionRequest(packet);
      } else if (packet.info == ">DISCONNECT<") {
        _handleDisconnection(packet);
      } else if (_connectedClients.contains(packet.source)) {
        _handleClientMessage(packet);
      }
    });
  }

  void _handleConnectionRequest(BbsPacket packet) {
    _log("Connection request from ${packet.source}");
    if (!_connectedClients.contains(packet.source)) {
      setState(() {
        _connectedClients.add(packet.source);
      });
      widget.tncController.sendBbsPacket(packet.source, ">CONN_ACK<");
      _log("Sent connection ACK to ${packet.source}. Client connected.");
    }
  }

  void _handleDisconnection(BbsPacket packet) {
    if (_connectedClients.contains(packet.source)) {
      _log("Client ${packet.source} has disconnected.");
      setState(() {
        _connectedClients.remove(packet.source);
      });
    }
  }

  void _handleClientMessage(BbsPacket packet) {
    _log("RX from ${packet.source}: ${packet.info}");
    // Simple ACK by echoing the message back
    widget.tncController.sendBbsPacket(
        packet.source, ">ACK< You said: ${packet.info}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BBS Server'),
      ),
      body: Column(
        children: [
          _buildControlCard(),
          const Divider(),
          _buildInfoSection(),
          const Divider(),
          Expanded(child: _buildLogView()),
        ],
      ),
    );
  }

  Widget _buildControlCard() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _callsignController,
              enabled: !_serverRunning,
              decoration: const InputDecoration(
                labelText: "BBS Callsign",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(_serverRunning ? Icons.stop : Icons.play_arrow),
                label: Text(_serverRunning ? "Stop Server" : "Start Server"),
                onPressed: _callsignController.text.trim().isEmpty ? null : _toggleServer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _serverRunning ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Connected Clients: ${_connectedClients.length}", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (_connectedClients.isEmpty)
            const Text("No clients connected.")
          else
            Wrap(
              spacing: 8.0,
              children: _connectedClients.map((call) => Chip(label: Text(call))).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildLogView() {
    return Card(
      margin: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0),
      child: _logMessages.isEmpty
          ? const Center(child: Text("Server log is empty."))
          : ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8.0),
              itemCount: _logMessages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(_logMessages[index]),
                );
              },
            ),
    );
  }
}