import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

final MapController _mapController = MapController();

class _MapPageState extends State<MapPage> {
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS tidak aktif');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permission di tolak');
    }

    return await Geolocator.getCurrentPosition();
  }

  LatLng? currentLocation;
  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  void _loadLocation() async {
    final pos = await _getCurrentLocation();
    final newLocation = LatLng(pos.latitude, pos.longitude);
    setState(() {
      currentLocation = LatLng(pos.latitude, pos.longitude);
    });

    _mapController.move(newLocation, 17);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map")),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: currentLocation ?? LatLng(3.595196, 98.672223),
          initialZoom: 17,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: "com.example.pertro_fleet",
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: currentLocation ?? LatLng(3.595196, 98.672223),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ],
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution('© OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    );
  }
}
