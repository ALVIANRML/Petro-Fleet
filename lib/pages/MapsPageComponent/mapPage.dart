import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

final MapController _mapController = MapController();

class _MapPageState extends State<MapPage> {
  String? kendaraanId;
  String? perjalananId;

  Future<void> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("GPS mati");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      print("Permission ditolak permanen");
      return;
    }
  }

  Future<LatLng?> getLokasiKendaraan(String idLogin) async {
    print("ini id login $idLogin");
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('perjalanan')
          .where('id_pengemudi', isEqualTo: idLogin)
          .where('status', isEqualTo: 'on_trip')
          .where('approved_by_driver', isEqualTo: true)
          .where('approved_arrival', isEqualTo: false)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      print("ini data$data");

      final lokasi = data['lokasi_berangkat'];

      if (lokasi == null) {
        print("lokasi_supir kosong");
        return null;
      }

      if (lokasi is! GeoPoint) {
        print("lokasi_supir bukan GeoPoint");
        return null;
      }
      final doc = snapshot.docs.first;

      perjalananId = doc.id;

      final kendaraanRef = doc.reference.parent.parent;
      kendaraanId = kendaraanRef?.id;
      return LatLng(lokasi.latitude, lokasi.longitude);
    } catch (e) {
      print("Error ambil lokasi: $e");
      return null;
    }
  }

  StreamSubscription<QuerySnapshot>? trackingListener;
  void listenTracking(String kendaraanId, String perjalananId) {
    trackingListener = FirebaseFirestore.instance
        .collection('kendaraan')
        .doc(kendaraanId)
        .collection('perjalanan')
        .doc(perjalananId)
        .collection('tracking')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isEmpty) return;

          final data = snapshot.docs.first.data();
          final GeoPoint posisi = data['posisi'];

          final newLatLng = LatLng(posisi.latitude, posisi.longitude);

          if (!mounted) return;

          setState(() {
            currentLocation = newLatLng;
          });

          _mapController.move(newLatLng, 17);
        });
  }

  LatLng? currentLocation;
  @override
  void initState() {
    super.initState();
    initTracking();
  }

  Future<void> initTracking() async {
    await checkPermission();
    await _loadLocation();

    if (kendaraanId == null || perjalananId == null) {
      print(
        "kendaraanId atau perjalananId masih null, tracking tidak dijalankan",
      );
      return;
    }

    listenTracking(kendaraanId!, perjalananId!);
    startTracking();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    trackingListener?.cancel();
    super.dispose();
  }

  void stopTracking() {
    positionStream?.cancel();
  }

  StreamSubscription<Position>? positionStream;
  void startTracking() {
    if (kendaraanId == null || perjalananId == null) {
      print("Tracking batal: kendaraanId/perjalananId null");
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    DateTime? lastSent;

    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) async {
            if (kendaraanId == null || perjalananId == null) {
              print("Skip simpan tracking karena ID null");
              return;
            }

            final now = DateTime.now();

            if (lastSent != null && now.difference(lastSent!).inSeconds < 5) {
              return;
            }

            lastSent = now;

            await FirebaseFirestore.instance
                .collection('kendaraan')
                .doc(kendaraanId!)
                .collection('perjalanan')
                .doc(perjalananId!)
                .collection('tracking')
                .add({
                  'posisi': GeoPoint(position.latitude, position.longitude),
                  'speed': position.speed,
                  'timestamp': FieldValue.serverTimestamp(),
                });
          },
        );
  }

  Future<void> _loadLocation() async {
    String? idLogin = FirebaseAuth.instance.currentUser?.uid;

    if (idLogin == null) {
      print("User belum login");
      return;
    }

    print("SEBELUM PANGGIL FUNCTION");

    final lokasiFirestore = await getLokasiKendaraan(idLogin);

    print("SESUDAH PANGGIL FUNCTION");

    if (lokasiFirestore != null) {
      setState(() {
        currentLocation = lokasiFirestore;

        // kirim data ke background
        if (kendaraanId != null && perjalananId != null) {
          final service = FlutterBackgroundService();

          service.invoke("setData", {
            "kendaraanId": kendaraanId,
            "perjalananId": perjalananId,
          });

          service.startService();
        }
      });
      print(" ini lokasiiii $currentLocation");

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(lokasiFirestore, 17);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map")),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: currentLocation ?? LatLng(3.495196, 98.672223),
          initialZoom: 17,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: "com.example.pertro_fleet",
          ),
          MarkerLayer(
            markers: currentLocation == null
                ? [] // ⬅️ kalau null, tidak ada marker
                : [
                    Marker(
                      point: currentLocation!,
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

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  String? kendaraanId;
  String? perjalananId;

  // nerima data dari UI
  service.on('setData').listen((event) {
    kendaraanId = event?['kendaraanId'];
    perjalananId = event?['perjalananId'];
  });

  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  ).listen((position) async {
    if (kendaraanId == null || perjalananId == null) return;

    await FirebaseFirestore.instance
        .collection('kendaraan')
        .doc(kendaraanId)
        .collection('perjalanan')
        .doc(perjalananId)
        .collection('tracking')
        .add({
          'posisi': GeoPoint(position.latitude, position.longitude),
          'speed': position.speed,
          'timestamp': FieldValue.serverTimestamp(),
        });
  });
}
