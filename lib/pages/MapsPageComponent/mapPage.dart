import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(3.595196, 98.672223),
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
                point: LatLng(3.595196, 98.672223),
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
