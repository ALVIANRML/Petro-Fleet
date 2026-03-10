import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1A1D),
      body: Padding(
        padding: const EdgeInsets.only(top: 70, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== PROFIL =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundImage: AssetImage('assets/img/download.jpg'),
                ),
                const SizedBox(width: 16),
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Petro Fleet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Administrator',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Menu",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

Container(
  margin:const EdgeInsets.symmetric(vertical:6),
decoration: BoxDecoration(
  color: const Color(0xFFD9D9D9),
  borderRadius: BorderRadius.circular(12)
),
           child: ListTile(
              leading: const Icon(Icons.person, color: Colors.black, fontWeight: FontWeight.bold,),
              title: const Text("Edit Profile",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward,
                  size: 16, color: Colors.black),
              onTap: () {},
            ),
),
Container(
  margin: const EdgeInsets.symmetric(vertical: 6),
  decoration : BoxDecoration(
    color: const Color(0xFFD9D9D9),
    borderRadius: BorderRadius.circular(12)
  ),

           child:  ListTile(
              leading: const Icon(Icons.logout_outlined, color: Colors.red, fontWeight: FontWeight.bold),
              title:
                  const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward,
                  size: 16, color: Colors.red),
              onTap: () {},
            ),
),
          ],
        ),
      ),
    );
  }
}