import 'package:flutter/material.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1A1D),
      body: const Center(
        child: Text(
          'Activity Page',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}