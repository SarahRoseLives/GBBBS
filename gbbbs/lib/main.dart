// main.dart

import 'package:flutter/material.dart';
import 'ui/homescreen/homescreen.dart';

void main() {
  runApp(const PacketChatApp());
}

class PacketChatApp extends StatelessWidget {
  const PacketChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PacketChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}