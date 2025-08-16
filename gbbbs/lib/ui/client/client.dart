import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/bbs_packet.dart';

enum ClientConnectionStatus { disconnected, connecting, connected, failed }

class ClientScreen extends StatefulWidget {
  final dynamic tncController;
  const ClientScreen({super.key, required this.tncController});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  ClientConnectionStatus _status = ClientConnectionStatus.disconnected;
  StreamSubscription? _bbsSubscription;
  int _selectedIndex = 0; // For the BottomNavigationBar

  final _userCallsignCtrl = TextEditingController(text: "N0CALL");
  final _serverCallsignCtrl = TextEditingController(text: "BBS-1");
  final List<String> _logMessages = [];
  String? _connectedCallsign;

  @override
  void dispose() {
    _bbsSubscription?.cancel();
    _userCallsignCtrl.dispose();
    _serverCallsignCtrl.dispose();
    super.dispose();
  }

  void _log(String message) {
    if (!mounted) return;
    setState(() {
      _logMessages.insert(0, "${TimeOfDay.now().format(context)} - $message");
    });
  }

  void _connectToBBS() {
    final userCall = _userCallsignCtrl.text.trim().toUpperCase();
    final serverCall = _serverCallsignCtrl.text.trim().toUpperCase();
    if (userCall.isEmpty || serverCall.isEmpty) return;

    setState(() {
      _status = ClientConnectionStatus.connecting;
      _logMessages.clear();
    });
    _log("Connecting to $serverCall as $userCall...");

    widget.tncController.userCallsign = userCall;
    _listenForPackets();
    widget.tncController.sendBbsPacket(serverCall, ">CONNECT<");
    _connectedCallsign = serverCall;

    // Timeout for connection
    Timer(const Duration(seconds: 15), () {
      if (_status == ClientConnectionStatus.connecting) {
        if (!mounted) return;
        setState(() => _status = ClientConnectionStatus.failed);
        _log("Connection failed: Timeout.");
        _bbsSubscription?.cancel();
      }
    });
  }

  void _disconnectFromBBS() {
    if (_connectedCallsign != null) {
      widget.tncController.sendBbsPacket(_connectedCallsign!, ">DISCONNECT<");
      _log("Sent disconnect notice to server.");
    }
    setState(() {
      _status = ClientConnectionStatus.disconnected;
      _connectedCallsign = null;
    });
    _bbsSubscription?.cancel();
    _log("Disconnected.");
  }

  void _listenForPackets() {
    _bbsSubscription?.cancel(); // Ensure only one listener is active
    _bbsSubscription = widget.tncController.bbsPacketStream.listen((packet) {
      if (!mounted) return;
      if (_status == ClientConnectionStatus.connecting &&
          packet.info == ">CONN_ACK<") {
        setState(() => _status = ClientConnectionStatus.connected);
        _log("Connection successful!");
      } else {
        _log("BBS > ${packet.info}");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BBS Client'),
      ),
      body: Column(
        children: [
          _buildStatusCard(),
          const Divider(height: 1),
          Expanded(
            child: _status == ClientConnectionStatus.connected
                ? _buildConnectedContent()
                : _buildLogView(),
          ),
        ],
      ),
      bottomNavigationBar: _status == ClientConnectionStatus.connected
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.forum_outlined),
                  label: 'Board',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.mail_outline),
                  label: 'Mail',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Me',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildStatusCard() {
    bool isDisconnected = _status == ClientConnectionStatus.disconnected ||
        _status == ClientConnectionStatus.failed;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userCallsignCtrl,
                  enabled: isDisconnected,
                  decoration: const InputDecoration(labelText: "Your Callsign"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _serverCallsignCtrl,
                  enabled: isDisconnected,
                  decoration: const InputDecoration(labelText: "BBS Callsign"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(isDisconnected ? Icons.login : Icons.logout),
              onPressed: isDisconnected ? _connectToBBS : _disconnectFromBBS,
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDisconnected ? Colors.green : Colors.red,
                  foregroundColor: Colors.white),
              label: Text(isDisconnected ? 'Connect' : 'Disconnect'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogView() {
    final statusText = {
      ClientConnectionStatus.disconnected: "Enter callsigns and connect to begin.",
      ClientConnectionStatus.failed: "Connection failed. Please try again.",
      ClientConnectionStatus.connecting: "Attempting to connect...",
      ClientConnectionStatus.connected: "", // Should not be seen here
    };

    return _logMessages.isEmpty
        ? Center(child: Text(statusText[_status] ?? ""))
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
          );
  }

  Widget _buildConnectedContent() {
    final List<Widget> pages = [
      _MessageBoard(bbsCallsign: _connectedCallsign ?? ""),
      _PrivateMessages(),
      _UserInfo(userCallsign: widget.tncController.userCallsign),
    ];
    return pages[_selectedIndex];
  }
}

// Message Board Tab
class _MessageBoard extends StatelessWidget {
  final String bbsCallsign;
  const _MessageBoard({required this.bbsCallsign});

  @override
  Widget build(BuildContext context) {
    final messages = [
      {"author": "K0ABC", "subject": "Field Day Plans", "body": "Who's coming?"},
      {"author": "W1XYZ", "subject": "Lost HT", "body": "Found an HT at the park, DM me."},
      {"author": "Sysop", "subject": "Welcome!", "body": "Welcome to $bbsCallsign BBS."},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: messages.length,
      itemBuilder: (context, idx) {
        final msg = messages[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(msg["subject"] ?? ""),
            subtitle: Text(msg["body"] ?? ""),
            leading: CircleAvatar(child: Text(msg["author"]![0])),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(msg["subject"] ?? ""),
                  content: Text("${msg["body"]}\n\nFrom: ${msg["author"]}"),
                  actions: [
                    TextButton(
                      child: const Text("Reply"),
                      onPressed: () {
                        Navigator.pop(context);
                        // Implement reply UI
                      },
                    ),
                    TextButton(
                      child: const Text("Close"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// Private Messages Tab
class _PrivateMessages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final messages = [
      {"from": "Sysop", "body": "Your registration is complete."},
      {"from": "W1XYZ", "body": "Meet at 10am?"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: messages.length,
      itemBuilder: (context, idx) {
        final msg = messages[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text("From: ${msg["from"]}"),
            subtitle: Text(msg["body"] ?? ""),
            trailing: const Icon(Icons.reply_outlined),
            onTap: () {
              // Implement reply UI
            },
          ),
        );
      },
    );
  }
}

// User Info Tab
class _UserInfo extends StatelessWidget {
  final String userCallsign;
  const _UserInfo({required this.userCallsign});
  @override
  Widget build(BuildContext context) {
    // Example user info
    const name = "Sarah";
    const unreadMessages = 1;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text("Callsign: $userCallsign", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text("Name: $name", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text("Unread Messages"),
              trailing: Text("$unreadMessages"),
            ),
          ),
        ],
      ),
    );
  }
}