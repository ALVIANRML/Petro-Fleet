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

  // ===== Helper Functions =====
  LatLng? parseLocation(dynamic lokasi) {
    if (lokasi is GeoPoint) return LatLng(lokasi.latitude, lokasi.longitude);
    if (lokasi is Map) {
      final lat = lokasi['latitude'];
      final lng = lokasi['longitude'];
      if (lat != null && lng != null)
        return LatLng(
          double.parse(lat.toString()),
          double.parse(lng.toString()),
        );
    }
    if (lokasi is List && lokasi.length == 2)
      return LatLng(
        double.parse(lokasi[0].toString()),
        double.parse(lokasi[1].toString()),
      );
    return null;
  }

  LatLng? getLokasiBerangkat(Map<String, dynamic> data) =>
      parseLocation(data['lokasi_berangkat']);
  LatLng? getLokasiAkhir(Map<String, dynamic> data) =>
      parseLocation(data['lokasi_akhir']);

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

    if (trackingSnapshot.docs.isEmpty) return null;
    return parseLocation(trackingSnapshot.docs.first.data()['posisi']);
  }

  // ===== Load Kendaraan =====
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

        // Ambil perjalanan aktif (on_trip) pertama
        final activeTripSnapshot = await kendaraanDoc.reference
            .collection('perjalanan')
            .where('status', isEqualTo: 'on_trip')
            .orderBy('created_at', descending: true)
            .limit(1)
            .get();

        QueryDocumentSnapshot<Map<String, dynamic>>? perjalananDoc;
        if (activeTripSnapshot.docs.isNotEmpty) {
          perjalananDoc = activeTripSnapshot.docs.first;
        } else {
          // Jika tidak ada perjalanan on_trip, ambil perjalanan terbaru
          final latestTripSnapshot = await kendaraanDoc.reference
              .collection('perjalanan')
              .orderBy('created_at', descending: true)
              .limit(1)
              .get();
          if (latestTripSnapshot.docs.isNotEmpty) {
            perjalananDoc = latestTripSnapshot.docs.first;
          }
        }

        if (perjalananDoc == null) continue;

        final perjalananData = perjalananDoc.data();
        final status = perjalananData['status'] ?? '';
        LatLng? posisiTerakhir;

        if (status == 'on_trip') {
          print("ini status on trip $status");
          posisiTerakhir = await getLastTrackingPosition(
            kendaraanId,
            perjalananDoc.id,
          );
          posisiTerakhir ??= getLokasiBerangkat(perjalananData);
        } else if (status == 'complete' || status == 'completed') {
          print("ini status complete $perjalananData");
          print("ini status complete $status");
          posisiTerakhir = getLokasiAkhir(perjalananData);
        } else {
          posisiTerakhir = getLokasiBerangkat(perjalananData);
          print("ini status in transit $status");
        }

        if (posisiTerakhir != null) {
          tempMarkers.add({
            'kendaraan_id': kendaraanId,
            'perjalanan_id': perjalananDoc.id,
            'plat_kendaraan': platKendaraan,
            'status': status,
            'position': posisiTerakhir,
            'prediksi_perbaikan': kendaraanData['prediksi_perbaikan'] ?? [],
            'rul_hari': kendaraanData['rul_hari'] ?? '-',
            'status_rul': kendaraanData['status_rul'] ?? '-',
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
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat posisi kendaraan: $e")),
      );
    }
  }

  // ===== UI Helper =====
  Color getMarkerColor(String status) {
    if (status == 'on_trip') return Colors.blue;
    if (status == 'completed') return Colors.green;
    return Colors.orange;
  }

  String getStatusLabel(String status) {
    if (status == 'on_trip') return 'On Trip';
    if (status == 'completed') return 'Complete';
    return 'In Transit';
  }

  void showKendaraanInfo(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['plat_kendaraan'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Status: ${getStatusLabel(item['status'])}"),
            const SizedBox(height: 8),
            Text("RUL: ${item['rul_hari']} Hari (${item['status_rul']})"),
            const SizedBox(height: 8),
            if ((item['prediksi_perbaikan'] as List).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Prediksi Perbaikan:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...List.generate(
                    item['prediksi_perbaikan'].length,
                    (index) => Text(
                      "${index + 1}. ${item['prediksi_perbaikan'][index]}",
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text("Kendaraan ID: ${item['kendaraan_id']}"),
            Text("Perjalanan ID: ${item['perjalanan_id']}"),
          ],
        ),
      ),
    );
  }

  // ===== Build Map =====
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
              setState(() => isLoading = true);
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
                  final position = item['position'];
                  final status = item['status'];
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
        ],
      ),
    );
  }
}
