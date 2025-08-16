import 'package:flutter/material.dart';

class TraditionalClientScreen extends StatefulWidget {
  const TraditionalClientScreen({super.key});

  @override
  State<TraditionalClientScreen> createState() => _TraditionalClientScreenState();
}

class _TraditionalClientScreenState extends State<TraditionalClientScreen> {
  final List<String> _messages = [
    "N0CALL> All: Welcome to the Go-Box BBS!",
    "K0ABC> All: Field Day is this weekend.",
    "W1XYZ> N0CALL: Found your HT, contact me.",
    "Sysop> All: Don't forget to check-in."
  ];

  final List<String> _terminalLines = [
    "Go-Box BBS v1.0",
    "Type 'help' for commands.",
    "> "
  ];

  final TextEditingController _terminalController = TextEditingController();

  void _sendTerminalCommand(String cmd) {
    setState(() {
      _terminalLines.add("> $cmd");
      // Simulate a response
      if (cmd.toLowerCase() == "help") {
        _terminalLines.add("Available commands: help, read, send, users, exit");
      } else if (cmd.toLowerCase() == "users") {
        _terminalLines.add("Active users: N0CALL, K0ABC, W1XYZ, Sysop");
      } else if (cmd.toLowerCase() == "exit") {
        _terminalLines.add("Session closed.");
      } else {
        _terminalLines.add("Unknown command: $cmd");
      }
      _terminalController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traditional Client'),
      ),
      body: Column(
        children: [
          // Messages on top
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.all(8.0),
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, idx) => ListTile(
                  leading: const Icon(Icons.message_outlined),
                  title: Text(_messages[idx]),
                ),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 2),
          // Terminal on bottom
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _terminalLines.length,
                      itemBuilder: (context, idx) => Text(
                        _terminalLines[idx],
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    color: Colors.black,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _terminalController,
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontFamily: 'monospace',
                            ),
                            decoration: const InputDecoration(
                              hintText: "Type command...",
                              hintStyle: TextStyle(color: Colors.greenAccent),
                              border: InputBorder.none,
                            ),
                            onSubmitted: _sendTerminalCommand,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.greenAccent),
                          onPressed: () {
                            final cmd = _terminalController.text.trim();
                            if (cmd.isNotEmpty) {
                              _sendTerminalCommand(cmd);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}