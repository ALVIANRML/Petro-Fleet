import 'package:flutter/material.dart';

class FleetPage extends StatelessWidget {
  const FleetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1A1D),
      body: const Center(
        child: Text(
          'Fleet Page',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}