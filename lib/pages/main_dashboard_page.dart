import 'package:flutter/material.dart';
import 'package:pertro_fleet/pages/MapsPageComponent/mapPageAdmin.dart';
import 'HomePageComponent/HomePage.dart';
import 'ProfilePageComponent/profile_page.dart';
import 'MapsPageComponent/mapPage.dart';
import 'ActivityPageComponent/activity_page.dart';
import 'FleetPageComponent/fleetPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatefulWidget {
  final int initialIndex;
  const DashboardPage({super.key, this.initialIndex = 0});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  final user = FirebaseAuth.instance.currentUser;
  String get uid => user!.uid;
  String nama = '';
  String jabatan = '';
  Future<void> getUserData() async {
    try {
      print("UID: $uid");

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      print("EXISTS: ${doc.exists}");
      print("DATA: ${doc.data()}");

      if (doc.exists) {
        setState(() {
          nama = doc['nama'] ?? '';
          jabatan = doc['posisi'] ?? '';
        });
      }
    } catch (e) {
      print("Error ambil user: $e");
    }
  }

  List<Widget> getPages() {
    print("ini jabatan $nama");
    return [
      HomePage(),
      jabatan == "Admin" ? MapPageAdmin() : MapPage(),
      ActivityPage(),
      FleetPage(),
      ProfilePage(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    getUserData(); // 🔥 ini yang kamu lupa
  }

  @override
  Widget build(BuildContext context) {
    if (jabatan.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: getPages()[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0B4996),
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: _buildItem(Icons.home, "Home", 0),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: _buildItem(Icons.map, "Maps", 1),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: _buildItem(Icons.add, "Activity", 2),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: _buildItem(Icons.local_shipping, "Fleet", 3),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: _buildItem(Icons.person, "Profile", 4),
            label: "",
          ),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : const Color(0xFF0A59BA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.black : const Color(0xFF878783),
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : const Color(0xFF878783),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
