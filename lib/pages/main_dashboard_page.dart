import 'package:flutter/material.dart';
import 'HomePageComponent/HomePage.dart';
import 'ProfilePageComponent/profile_page.dart';
import 'MapsPageComponent/mapPage.dart';
import 'ActivityPageComponent/activity_page.dart';
import 'FleetPageComponent/fleetPage.dart';

class DashboardPage extends StatefulWidget {
  final int initialIndex;
  const DashboardPage({super.key, this.initialIndex = 0});

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
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
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
