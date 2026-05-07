import 'package:flutter/material.dart';
import 'package:pertro_fleet/pages/ActivityPageComponent/activity_data_perjalanan.dart';
import 'package:pertro_fleet/pages/ActivityPageComponent/activity_data_service.dart';
import 'package:pertro_fleet/pages/ActivityPageComponent/activity_list_pekerjaan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  Future<String?> getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return userDoc.data()?['posisi'];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data;

        return Scaffold(
          backgroundColor: const Color(0xFF0B4996),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // 🔥 ADMIN
                if (role == 'Admin') ...[
                  ActivityCard(
                    image: "assets/img/image_data_perjalanan.png",
                    title: "Data Perjalanan",
                    icon: Icons.settings,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DataPerjalananPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  ActivityCard(
                    image: "assets/img/image_data_service.png",
                    title: "Data Service",
                    icon: Icons.directions_car,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DataServicePage(),
                        ),
                      );
                    },
                  ),
                ],

                // 🔥 DRIVER
                if (role == 'Sopir') ...[
                  ActivityCard(
                    image: "assets/img/image_list_pekerjaan.png",
                    title: "List Pekerjaan",
                    icon: Icons.directions_car,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ListPekerjaanPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  ActivityCard(
                    image: "assets/img/image_history_pekerjaan.png",
                    title: "Histori Pekerjaan",
                    icon: Icons.history,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ListPekerjaanPage(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class ActivityCard extends StatelessWidget {
  final String image;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const ActivityCard({
    super.key,
    required this.image,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Image.asset(
              image,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              cacheWidth: 600,
            ),
            // ignore: deprecated_member_use
            Container(height: 150, color: Colors.white.withOpacity(0.6)),

            Positioned(
              top: 10,
              right: 10,
              child: Icon(icon, color: Colors.black87, size: 28),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
