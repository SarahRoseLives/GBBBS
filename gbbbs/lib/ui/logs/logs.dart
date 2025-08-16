import 'package:flutter/material.dart';
import '../../models/aprs_packet.dart';

class LogsScreen extends StatelessWidget {
  final ValueNotifier<List<AprsPacket>> aprsPacketsNotifier;

  const LogsScreen({
    super.key,
    required this.aprsPacketsNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Packet Logs'),
      ),
      body: ValueListenableBuilder<List<AprsPacket>>(
        valueListenable: aprsPacketsNotifier,
        builder: (context, packets, child) {
          if (packets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Listening for packets..."),
                ],
              ),
            );
          }
          // Display packets in reverse chronological order so the newest are at the top.
          final reversedPackets = packets.reversed.toList();
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: reversedPackets.length,
            itemBuilder: (context, index) {
              final packet = reversedPackets[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text('${packet.source} > ${packet.destination}'),
                  subtitle: Text(packet.info.trim()),
                  trailing: Text(
                    '${packet.timestamp.hour.toString().padLeft(2, '0')}:${packet.timestamp.minute.toString().padLeft(2, '0')}:${packet.timestamp.second.toString().padLeft(2, '0')}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}