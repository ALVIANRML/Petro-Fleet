import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pertro_fleet/firebase_options.dart';
import 'pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/main_dashboard_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ minta izin notif (WAJIB Android 13+)
  await Permission.notification.request();

  // ✅ INIT NOTIF (INI YANG KAMU BELUM ADA)
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  // ✅ baru init background service

  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
    ),
    iosConfiguration: IosConfiguration(
      // 🔥 TAMBAH INI
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Petro Fleet',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const DashboardPage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  String? kendaraanId;
  String? perjalananId;

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

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
