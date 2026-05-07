import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapPageAdmin extends StatefulWidget {
  const MapPageAdmin({super.key});

  @override
  State<MapPageAdmin> createState() => _MapPageAdminState();
}

final MapController _mapController = MapController();

class _MapPageAdminState extends State<MapPageAdmin> {
  List<Map<String, dynamic>> kendaraanMarkers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAllKendaraanPosition();
  }

  Future<void> loadAllKendaraanPosition() async {
    try {
      final kendaraanSnapshot = await FirebaseFirestore.instance
          .collection('kendaraan')
          .get();

      final List<Map<String, dynamic>> tempMarkers = [];

      for (final kendaraanDoc in kendaraanSnapshot.docs) {
        final kendaraanId = kendaraanDoc.id;
        final kendaraanData = kendaraanDoc.data();
        final platKendaraan = kendaraanData['plat_kendaraan'] ?? '-';

        final perjalananSnapshot = await kendaraanDoc.reference
            .collection('perjalanan')
            .orderBy('created_at', descending: true)
            .limit(1)
            .get();

        if (perjalananSnapshot.docs.isEmpty) {
          continue;
        }

        final perjalananDoc = perjalananSnapshot.docs.first;
        final perjalananData = perjalananDoc.data();

        final status = perjalananData['status'] ?? '';
        LatLng? posisiTerakhir;

        if (status == 'on_trip') {
          posisiTerakhir = await getLastTrackingPosition(
            kendaraanId,
            perjalananDoc.id,
          );
        } else {
          posisiTerakhir = getPositionFromPerjalanan(perjalananData);
        }

        if (posisiTerakhir != null) {
          tempMarkers.add({
            'kendaraan_id': kendaraanId,
            'perjalanan_id': perjalananDoc.id,
            'plat_kendaraan': platKendaraan,
            'status': status,
            'position': posisiTerakhir,
          });
        }
      }

      if (!mounted) return;

      setState(() {
        kendaraanMarkers = tempMarkers;
        isLoading = false;
      });

      if (kendaraanMarkers.isNotEmpty) {
        _mapController.move(kendaraanMarkers.first['position'], 13);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat posisi kendaraan: $e")),
      );
    }
  }

  Future<LatLng?> getLastTrackingPosition(
    String kendaraanId,
    String perjalananId,
  ) async {
    final trackingSnapshot = await FirebaseFirestore.instance
        .collection('kendaraan')
        .doc(kendaraanId)
        .collection('perjalanan')
        .doc(perjalananId)
        .collection('tracking')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (trackingSnapshot.docs.isEmpty) {
      return null;
    }

    final data = trackingSnapshot.docs.first.data();
    final posisi = data['posisi'];

    if (posisi is GeoPoint) {
      return LatLng(posisi.latitude, posisi.longitude);
    }

    return null;
  }

  LatLng? getPositionFromPerjalanan(Map<String, dynamic> data) {
    final lokasiAkhir = data['lokasi_akhir'];
    final lokasiBerangkat = data['lokasi_berangkat'];

    if (lokasiAkhir is GeoPoint) {
      return LatLng(lokasiAkhir.latitude, lokasiAkhir.longitude);
    }

    if (lokasiAkhir is Map) {
      final lat = lokasiAkhir['latitude'];
      final lng = lokasiAkhir['longitude'];

      if (lat != null && lng != null) {
        return LatLng(
          double.parse(lat.toString()),
          double.parse(lng.toString()),
        );
      }
    }

    if (lokasiBerangkat is GeoPoint) {
      return LatLng(lokasiBerangkat.latitude, lokasiBerangkat.longitude);
    }

    return null;
  }

  Color getMarkerColor(String status) {
    if (status == 'on_trip') {
      return Colors.blue;
    } else if (status == 'completed') {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  String getStatusLabel(String status) {
    if (status == 'on_trip') {
      return 'On Trip';
    } else if (status == 'completed') {
      return 'Completed';
    } else {
      return 'In Transit';
    }
  }

  void showKendaraanInfo(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['plat_kendaraan'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text("Status: ${getStatusLabel(item['status'])}"),
              const SizedBox(height: 8),
              Text("Kendaraan ID: ${item['kendaraan_id']}"),
              Text("Perjalanan ID: ${item['perjalanan_id']}"),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const defaultLocation = LatLng(3.595196, 98.672223);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Map Admin"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              loadAllKendaraanPosition();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: defaultLocation,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.example.pertro_fleet",
              ),
              MarkerLayer(
                markers: kendaraanMarkers.map((item) {
                  final LatLng position = item['position'];
                  final String status = item['status'];

                  return Marker(
                    point: position,
                    width: 80,
                    height: 80,
                    child: GestureDetector(
                      onTap: () => showKendaraanInfo(item),
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            color: getMarkerColor(status),
                            size: 34,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['plat_kendaraan'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),

          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Jumlah kendaraan tampil: ${kendaraanMarkers.length}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
