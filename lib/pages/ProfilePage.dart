import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top:70, left:20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundImage: const AssetImage('assets/img/download.jpg'),
          ),
          const SizedBox(width: 16),
          Padding(padding: const EdgeInsets.only(top:20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Admin Petro Fleet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Administrator', style: TextStyle(color: Colors.grey)),
            ],
          ),
          ),
        ],
      ),
    );
  }
}
