import 'package:flutter/material.dart';

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus AI',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const Scaffold(
        body: Center(child: Text('Nexus AI')),
      ),
    );
  }
}
