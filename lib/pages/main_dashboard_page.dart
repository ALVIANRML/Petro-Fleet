import 'package:flutter/material.dart';
import 'HomePageComponent/HomePage.dart';
import 'profile_page.dart';
import 'MapsPageComponent/mapPage.dart';
import 'activity_page.dart';
import 'fleetPage.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    MapPage(),
    ActivityPage(),
    FleetPage(),
    ProfilePage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1B1A1D),
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
        color: isSelected ? Colors.white : const Color(0xFF23241F),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.black : Colors.white),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
