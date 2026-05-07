import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pertro_fleet/pages/FleetPageComponent/firebase_range_service.dart';
import 'package:pertro_fleet/pages/FleetPageComponent/rul_api_service.dart';

class DetailFleetPage extends StatefulWidget {
  final String kendaraanId;
  final Map<String, dynamic> kendaraan;

  const DetailFleetPage({
    super.key,
    required this.kendaraanId,
    required this.kendaraan,
  });

  @override
  State<DetailFleetPage> createState() => _DetailFleetPageState();
}

class _DetailFleetPageState extends State<DetailFleetPage> {
  bool isPredicting = false;
  final Random random = Random();

  String randomKondisi() {
    final kondisi = ['Baik', 'Sedang', 'Buruk'];
    return kondisi[random.nextInt(kondisi.length)];
  }

  int kondisiToScore(String kondisi) {
    if (kondisi == 'Baik') return 100;
    if (kondisi == 'Sedang') return 50;
    if (kondisi == 'Buruk') return 0;
    return 50;
  }

  double randomRange(double min, double max) {
    return min + random.nextDouble() * (max - min);
  }

  Map<String, dynamic> generateDummyCondition() {
    final kondisiRem = randomKondisi();
    final kondisiBaterai = randomKondisi();
    final kondisiOli = randomKondisi();
    final kondisiGetaran = randomKondisi();
    final kondisiBan = randomKondisi();
    final kondisiFuel = randomKondisi();

    final brakeScore = kondisiToScore(kondisiRem);
    final batteryScore = kondisiToScore(kondisiBaterai);
    final oilScore = kondisiToScore(kondisiOli);

    double tirePressure;
    if (kondisiBan == 'Baik') {
      tirePressure = randomRange(32, 36);
    } else if (kondisiBan == 'Sedang') {
      tirePressure = randomRange(28, 31);
    } else {
      tirePressure = randomRange(20, 27);
    }

    double fuelConsumption;
    if (kondisiFuel == 'Baik') {
      fuelConsumption = randomRange(8, 12);
    } else if (kondisiFuel == 'Sedang') {
      fuelConsumption = randomRange(13, 16);
    } else {
      fuelConsumption = randomRange(17, 24);
    }

    double vibrationLevel;
    if (kondisiGetaran == 'Baik') {
      vibrationLevel = randomRange(5, 20);
    } else if (kondisiGetaran == 'Sedang') {
      vibrationLevel = randomRange(21, 49);
    } else {
      vibrationLevel = randomRange(50, 90);
    }

    double engineTemperature;
    if (kondisiRem == 'Buruk' ||
        kondisiBaterai == 'Buruk' ||
        kondisiOli == 'Buruk') {
      engineTemperature = randomRange(110, 125);
    } else if (kondisiRem == 'Sedang' ||
        kondisiBaterai == 'Sedang' ||
        kondisiOli == 'Sedang') {
      engineTemperature = randomRange(95, 109);
    } else {
      engineTemperature = randomRange(80, 94);
    }

    final adaKerusakan =
        kondisiRem == 'Buruk' ||
        kondisiBaterai == 'Buruk' ||
        kondisiOli == 'Buruk' ||
        kondisiBan == 'Buruk' ||
        kondisiGetaran == 'Buruk' ||
        kondisiFuel == 'Buruk';

    return {
      'kondisi_rem': kondisiRem,
      'kondisi_baterai': kondisiBaterai,
      'kondisi_oli': kondisiOli,
      'kondisi_ban': kondisiBan,
      'kondisi_getaran': kondisiGetaran,
      'kondisi_fuel': kondisiFuel,

      'brake_condition': brakeScore,
      'battery_status': batteryScore,
      'oil_quality': oilScore,
      'tire_preasure': double.parse(tirePressure.toStringAsFixed(2)),
      'fuel_consumtion': double.parse(fuelConsumption.toStringAsFixed(2)),
      'vibration_level': double.parse(vibrationLevel.toStringAsFixed(2)),
      'engine_temperature': double.parse(engineTemperature.toStringAsFixed(2)),

      'kecelakaan': adaKerusakan ? 'Ya' : 'Tidak',
      'catatan_kerusakan': adaKerusakan
          ? 'Terdapat indikasi kondisi komponen kurang baik'
          : '-',
    };
  }

  double getDoubleValue(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;

    if (value is num) return value.toDouble();

    String text = value.toString().trim();

    text = text.replaceAll(',', '.');

    final result = double.tryParse(text);
    return result ?? defaultValue;
  }

  int getIntValue(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;

    if (value is int) return value;
    if (value is num) return value.toInt();

    final result = int.tryParse(value.toString());
    return result ?? defaultValue;
  }

  Future<void> createDummyFirebaseData() async {
    try {
      final now = DateTime.now();

      final kendaraanRef = FirebaseFirestore.instance
          .collection('kendaraan')
          .doc(widget.kendaraanId);

      final perjalananRef = kendaraanRef.collection('perjalanan');
      final serviceRef = kendaraanRef.collection('service');
      final observasiRef = kendaraanRef.collection('observasi_mingguan');

      // Update field utama kendaraan agar tidak kosong
      await kendaraanRef.set({
        'tahun_produksi': widget.kendaraan['tahun_produksi'] ?? 2020,
        'total_jam_operasi': widget.kendaraan['total_jam_operasi'] ?? 120,
        'kapasitas_muatan': widget.kendaraan['kapasitas_muatan'] ?? 5000,
      }, SetOptions(merge: true));

      // Dummy perjalanan untuk 7 hari terakhir
      await perjalananRef.add({
        'tanggal': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'total_jumlah_muatan': 4400,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Dummy service untuk 7 hari terakhir
      await serviceRef.add({
        'tanggal_perbaikan': Timestamp.fromDate(
          now.subtract(const Duration(days: 1)),
        ),
        'kondisi_rem': 'Baik',
        'kondisi_baterai': 'Baik',
        'tekanan_ban': 35,
        'konsumsi_bahan_bakar': 12,
        'tingkat_getaran': 3,
        'kualitas_oli': 80,
        'kecelakaan': 'Tidak',
        'created_at': FieldValue.serverTimestamp(),
      });

      // Dummy observasi minggu ke-1
      await observasiRef.add({
        'Record_No': 1,
        'Year_of_Manufacture': 2020,
        'Usage_Hours': 100,
        'Load_Capacity': 5000,
        'Actual_Load': 4200,
        'Engine_Temperature': 90,
        'Tire_Pressure': 35,
        'Fuel_Consumption': 12,
        'Battery_Status': 100,
        'Vibration_Levels': 50,
        'Oil_Quality': 100,
        'Failure_History': 0,
        'Anomalies_Detected': 0,
        'Delivery_Times': 2,
        'Elapsed_Days': 0,
        'Days_Since_Last_Observation': 0,
        'Observation_Month': now.subtract(const Duration(days: 21)).month,
        'Observation_DayOfYear': dayOfYear(
          now.subtract(const Duration(days: 21)),
        ),
        'Route_Info_Rural': 0,
        'Route_Info_Urban': 1,
        'Brake_Condition_Good': 1,
        'Brake_Condition_Poor': 0,
        'tanggal_mulai': Timestamp.fromDate(
          now.subtract(const Duration(days: 28)),
        ),
        'tanggal_akhir': Timestamp.fromDate(
          now.subtract(const Duration(days: 21)),
        ),
        'created_at': FieldValue.serverTimestamp(),
      });

      // Dummy observasi minggu ke-2
      await observasiRef.add({
        'Record_No': 2,
        'Year_of_Manufacture': 2020,
        'Usage_Hours': 110,
        'Load_Capacity': 5000,
        'Actual_Load': 4300,
        'Engine_Temperature': 92,
        'Tire_Pressure': 34,
        'Fuel_Consumption': 13,
        'Battery_Status': 100,
        'Vibration_Levels': 50,
        'Oil_Quality': 100,
        'Failure_History': 0,
        'Anomalies_Detected': 0,
        'Delivery_Times': 2,
        'Elapsed_Days': 7,
        'Days_Since_Last_Observation': 7,
        'Observation_Month': now.subtract(const Duration(days: 14)).month,
        'Observation_DayOfYear': dayOfYear(
          now.subtract(const Duration(days: 14)),
        ),
        'Route_Info_Rural': 0,
        'Route_Info_Urban': 1,
        'Brake_Condition_Good': 1,
        'Brake_Condition_Poor': 0,
        'tanggal_mulai': Timestamp.fromDate(
          now.subtract(const Duration(days: 21)),
        ),
        'tanggal_akhir': Timestamp.fromDate(
          now.subtract(const Duration(days: 14)),
        ),
        'created_at': FieldValue.serverTimestamp(),
      });

      // Dummy observasi minggu ke-3
      await observasiRef.add({
        'Record_No': 3,
        'Year_of_Manufacture': 2020,
        'Usage_Hours': 120,
        'Load_Capacity': 5000,
        'Actual_Load': 4400,
        'Engine_Temperature': 95,
        'Tire_Pressure': 33,
        'Fuel_Consumption': 14,
        'Battery_Status': 100,
        'Vibration_Levels': 50,
        'Oil_Quality': 100,
        'Failure_History': 0,
        'Anomalies_Detected': 0,
        'Delivery_Times': 2,
        'Elapsed_Days': 14,
        'Days_Since_Last_Observation': 7,
        'Observation_Month': now.subtract(const Duration(days: 7)).month,
        'Observation_DayOfYear': dayOfYear(
          now.subtract(const Duration(days: 7)),
        ),
        'Route_Info_Rural': 0,
        'Route_Info_Urban': 1,
        'Brake_Condition_Good': 1,
        'Brake_Condition_Poor': 0,
        'tanggal_mulai': Timestamp.fromDate(
          now.subtract(const Duration(days: 14)),
        ),
        'tanggal_akhir': Timestamp.fromDate(
          now.subtract(const Duration(days: 7)),
        ),
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dummy data berhasil dibuat di Firebase")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal membuat dummy data: $e")));
    }
  }

  List<String> getRekomendasiPerbaikan({
    required Map<String, dynamic> observation,
    required String statusRul,
  }) {
    List<String> rekomendasi = [];

    final engineTemp =
        double.tryParse(observation['Engine_Temperature'].toString()) ?? 0;

    final tirePressure =
        double.tryParse(observation['Tire_Pressure'].toString()) ?? 0;

    final fuelConsumption =
        double.tryParse(observation['Fuel_Consumption'].toString()) ?? 0;

    final batteryStatus =
        double.tryParse(observation['Battery_Status'].toString()) ?? 0;

    final vibrationLevels =
        double.tryParse(observation['Vibration_Levels'].toString()) ?? 0;

    final oilQuality =
        double.tryParse(observation['Oil_Quality'].toString()) ?? 0;

    final brakeGood = observation['Brake_Condition_Good'] ?? 0;
    final brakePoor = observation['Brake_Condition_Poor'] ?? 0;

    final failureHistory = observation['Failure_History'] ?? 0;
    final anomaliesDetected = observation['Anomalies_Detected'] ?? 0;

    if (engineTemp >= 110) {
      rekomendasi.add("Periksa sistem pendingin mesin dan radiator");
    }

    if (tirePressure < 30) {
      rekomendasi.add("Periksa dan tambah tekanan ban");
    }

    if (tirePressure > 40) {
      rekomendasi.add("Kurangi tekanan ban agar sesuai standar");
    }

    if (fuelConsumption > 15) {
      rekomendasi.add("Periksa sistem bahan bakar dan efisiensi mesin");
    }

    if (batteryStatus <= 50) {
      rekomendasi.add("Periksa atau ganti baterai kendaraan");
    }

    if (vibrationLevels >= 50) {
      rekomendasi.add(
        "Periksa getaran mesin, bearing, dan kaki-kaki kendaraan",
      );
    }

    if (oilQuality <= 50) {
      rekomendasi.add("Ganti oli mesin");
    }

    if (brakePoor == 1) {
      rekomendasi.add("Periksa atau ganti sistem rem");
    }

    if (brakeGood == 0 && brakePoor == 0) {
      rekomendasi.add("Lakukan pengecekan kondisi rem secara berkala");
    }

    if (failureHistory == 1) {
      rekomendasi.add(
        "Lakukan inspeksi menyeluruh karena ada riwayat kerusakan",
      );
    }

    if (anomaliesDetected == 1) {
      rekomendasi.add(
        "Periksa anomali kendaraan berdasarkan data service terakhir",
      );
    }

    if (statusRul.contains("Merah")) {
      rekomendasi.add("Prioritaskan kendaraan untuk perawatan segera");
    } else if (statusRul.contains("Jingga")) {
      rekomendasi.add("Jadwalkan perawatan preventif dalam waktu dekat");
    } else if (statusRul.contains("Hijau")) {
      rekomendasi.add("Kendaraan masih aman, lanjutkan monitoring rutin");
    }

    if (rekomendasi.isEmpty) {
      rekomendasi.add("Tidak ada perbaikan khusus, lakukan perawatan rutin");
    }

    return rekomendasi;
  }

  final FirebaseRangeService rangeService = FirebaseRangeService();

  final RulApiService rulApiService = RulApiService(
    baseUrl: 'http://192.168.18.223:5000',
  );
  int dayOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    return date.difference(startOfYear).inDays + 1;
  }

  double mapBatteryStatus(String? kondisi) {
    if (kondisi == 'Baik') return 100.0;
    if (kondisi == 'Sedang') return 50.0;
    if (kondisi == 'Buruk') return 0.0;
    return 50.0;
  }

  Color getStatusColor(dynamic status) {
    final text = status?.toString() ?? '';

    if (text.contains('Hijau')) return Colors.green;
    if (text.contains('Jingga')) return Colors.orange;
    if (text.contains('Merah')) return Colors.red;

    return Colors.black;
  }

  String formatEstimasi(dynamic estimasi) {
    if (estimasi == null) return "-";

    if (estimasi is num) {
      return "${estimasi.toStringAsFixed(2)} hari";
    }

    final angka = double.tryParse(estimasi.toString());
    if (angka == null) return "-";

    return "${angka.toStringAsFixed(2)} hari";
  }

  Map<String, dynamic> buildWeeklyObservation({
    required Map<String, dynamic> kendaraan,
    required List<Map<String, dynamic>> perjalanan,
    required List<Map<String, dynamic>> service,
    required DateTime startDate,
    required DateTime endDate,
    required int recordNo,
    required int elapsedDays,
    required int daysSinceLastObservation,
  }) {
    final tahunProduksi = getIntValue(
      kendaraan['tahun_produksi'],
      defaultValue: 2020,
    );

    final usageHours = getDoubleValue(
      kendaraan['total_jam_operasi'],
      defaultValue: 0.0,
    );

    final loadCapacity = getDoubleValue(
      kendaraan['kapasitas_muatan'],
      defaultValue: 10.0,
    );

    double actualLoad = 0.0;

    if (perjalanan.isNotEmpty) {
      final lastPerjalanan = perjalanan.last;

      actualLoad = getDoubleValue(
        lastPerjalanan['total_jumlah_muatan'],
        defaultValue: 0.0,
      );

      if (actualLoad == 0.0 && lastPerjalanan['muatan'] is List) {
        final List muatanList = lastPerjalanan['muatan'];

        for (final item in muatanList) {
          if (item is Map<String, dynamic>) {
            actualLoad += getDoubleValue(
              item['jumlah_muatan'],
              defaultValue: 0.0,
            );
          }
        }
      }
    }

    final lastService = service.isNotEmpty ? service.last : <String, dynamic>{};

    final brakeCondition = getDoubleValue(
      lastService['brake_condition'],
      defaultValue: 50.0,
    );

    final batteryStatus = getDoubleValue(
      lastService['battery_status'],
      defaultValue: 50.0,
    );

    final tirePressure = getDoubleValue(
      lastService['tire_preasure'],
      defaultValue: 35.0,
    );

    final fuelConsumption = getDoubleValue(
      lastService['fuel_consumtion'],
      defaultValue: 12.0,
    );

    final vibrationLevel = getDoubleValue(
      lastService['vibration_level'],
      defaultValue: 3.0,
    );

    final oilQuality = getDoubleValue(
      lastService['oil_quality'],
      defaultValue: 80.0,
    );

    final kecelakaan =
        lastService['kecelakaan']?.toString().toLowerCase() ?? '';
    final catatanKerusakan =
        lastService['catatan_kerusakan']?.toString().toLowerCase() ?? '';

    final failureHistory =
        kecelakaan == 'ya' ||
            catatanKerusakan != '-' && catatanKerusakan.isNotEmpty
        ? 1
        : 0;

    final anomaliesDetected = service.isNotEmpty ? 1 : 0;

    final routeUrban = 1;
    final routeRural = 0;

    return {
      'Record_No': recordNo,
      'Year_of_Manufacture': tahunProduksi,
      'Usage_Hours': usageHours,
      'Load_Capacity': loadCapacity,
      'Actual_Load': actualLoad,

      'Engine_Temperature': 120,
      'Tire_Pressure': tirePressure,
      'Fuel_Consumption': fuelConsumption,
      'Battery_Status': batteryStatus,
      'Vibration_Levels': vibrationLevel,
      'Oil_Quality': oilQuality,

      'Failure_History': failureHistory,
      'Anomalies_Detected': anomaliesDetected,
      'Delivery_Times': 60,

      'Elapsed_Days': elapsedDays,
      'Days_Since_Last_Observation': daysSinceLastObservation,
      'Observation_Month': endDate.month,
      'Observation_DayOfYear': dayOfYear(endDate),

      'Route_Info_Rural': routeRural,
      'Route_Info_Urban': routeUrban,

      'Brake_Condition_Good': brakeCondition >= 80 ? 1 : 0,
      'Brake_Condition_Poor': brakeCondition <= 40 ? 1 : 0,
    };
  }

  Map<String, dynamic> cleanObservationForApi(Map<String, dynamic> data) {
    return {
      'Record_No': data['Record_No'],
      'Year_of_Manufacture': data['Year_of_Manufacture'],
      'Usage_Hours': data['Usage_Hours'],
      'Load_Capacity': data['Load_Capacity'],
      'Actual_Load': data['Actual_Load'],
      'Engine_Temperature': data['Engine_Temperature'],
      'Tire_Pressure': data['Tire_Pressure'],
      'Fuel_Consumption': data['Fuel_Consumption'],
      'Battery_Status': data['Battery_Status'],
      'Vibration_Levels': data['Vibration_Levels'],
      'Oil_Quality': data['Oil_Quality'],
      'Failure_History': data['Failure_History'],
      'Anomalies_Detected': data['Anomalies_Detected'],
      'Delivery_Times': data['Delivery_Times'],
      'Elapsed_Days': data['Elapsed_Days'],
      'Days_Since_Last_Observation': data['Days_Since_Last_Observation'],
      'Observation_Month': data['Observation_Month'],
      'Observation_DayOfYear': data['Observation_DayOfYear'],
      'Route_Info_Rural': data['Route_Info_Rural'],
      'Route_Info_Urban': data['Route_Info_Urban'],
      'Brake_Condition_Good': data['Brake_Condition_Good'],
      'Brake_Condition_Poor': data['Brake_Condition_Poor'],
    };
  }

  Future<void> createDummyAndRunPrediction() async {
    await createDummyFirebaseData();
    await runPrediction();
  }

  Future<void> runPrediction() async {
    try {
      setState(() {
        isPredicting = true;
      });

      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      final perjalanan = await rangeService.getPerjalananByRange(
        kendaraanId: widget.kendaraanId,
        startDate: startDate,
        endDate: endDate,
      );

      final service = await rangeService.getServiceByRange(
        kendaraanId: widget.kendaraanId,
        startDate: startDate,
        endDate: endDate,
      );

      if (perjalanan.isEmpty && service.isEmpty) {
        throw Exception(
          "Tidak ada data perjalanan/service pada 7 hari terakhir.",
        );
      }

      final observasiRef = FirebaseFirestore.instance
          .collection('kendaraan')
          .doc(widget.kendaraanId)
          .collection('observasi_mingguan');

      final oldSnapshot = await observasiRef
          .orderBy('tanggal_akhir', descending: true)
          .limit(1)
          .get();

      int recordNo = 1;
      int elapsedDays = 0;
      int daysSinceLastObservation = 0;

      if (oldSnapshot.docs.isNotEmpty) {
        final lastData = oldSnapshot.docs.first.data();

        final lastRecordNo = lastData['Record_No'] ?? 0;
        recordNo = (lastRecordNo as num).toInt() + 1;

        final firstSnapshot = await observasiRef
            .orderBy('tanggal_akhir')
            .limit(1)
            .get();

        if (firstSnapshot.docs.isNotEmpty) {
          final firstTanggal = firstSnapshot.docs.first.data()['tanggal_akhir'];

          if (firstTanggal is Timestamp) {
            final firstDate = firstTanggal.toDate();
            elapsedDays = endDate.difference(firstDate).inDays;
          }
        }

        final lastTanggal = lastData['tanggal_akhir'];

        if (lastTanggal is Timestamp) {
          final lastDate = lastTanggal.toDate();
          daysSinceLastObservation = endDate.difference(lastDate).inDays;
        }
      }

      final observation = buildWeeklyObservation(
        kendaraan: widget.kendaraan,
        perjalanan: perjalanan,
        service: service,
        startDate: startDate,
        endDate: endDate,
        recordNo: recordNo,
        elapsedDays: elapsedDays,
        daysSinceLastObservation: daysSinceLastObservation,
      );

      await observasiRef.add({
        ...observation,
        'tanggal_mulai': Timestamp.fromDate(startDate),
        'tanggal_akhir': Timestamp.fromDate(endDate),
        'created_at': FieldValue.serverTimestamp(),
      });

      final lastThreeSnapshot = await observasiRef
          .orderBy('tanggal_akhir', descending: true)
          .limit(3)
          .get();

      final observations = lastThreeSnapshot.docs
          .map((doc) => cleanObservationForApi(doc.data()))
          .toList()
          .reversed
          .toList();

      if (observations.length < 3) {
        throw Exception(
          "Data observasi belum cukup. Minimal butuh 3 minggu data.",
        );
      }

      final result = await rulApiService.predictRul(observations);

      final prediksiRulHari = (result['prediksi_rul_hari'] as num).toDouble();
      final status = result['status'].toString();
      final latestObservation = observations.last;

      final rekomendasiPerbaikan = getRekomendasiPerbaikan(
        observation: latestObservation,
        statusRul: status,
      );

      await FirebaseFirestore.instance
          .collection('kendaraan')
          .doc(widget.kendaraanId)
          .set({
            'estimasi_masa_pakai': prediksiRulHari,
            'rul_hari': prediksiRulHari,
            'status_rul': status,
            'prediksi_perbaikan': rekomendasiPerbaikan,
            'last_prediction_at': FieldValue.serverTimestamp(),
            'last_prediction_start': Timestamp.fromDate(startDate),
            'last_prediction_end': Timestamp.fromDate(endDate),
          }, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection('kendaraan')
          .doc(widget.kendaraanId)
          .collection('prediksi_rul')
          .add({
            'prediksi_rul_hari': prediksiRulHari,
            'status': status,
            'prediksi_perbaikan': rekomendasiPerbaikan,
            'tanggal_mulai': Timestamp.fromDate(startDate),
            'tanggal_selesai': Timestamp.fromDate(endDate),
            'created_at': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Prediksi berhasil: ${prediksiRulHari.toStringAsFixed(2)} hari - $status",
          ),
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal prediksi: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isPredicting = false;
        });
      }
    }
  }

  Widget detailItem(String title, dynamic value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B4996),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? "-",
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget predictionCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('kendaraan')
          .doc(widget.kendaraanId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;

        final estimasi = data?['estimasi_masa_pakai'];
        final status = data?['status_rul'];
        final prediksiPerbaikan = data?['prediksi_perbaikan'];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Prediksi ML",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B4996),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                "Estimasi Sisa Pakai: ${formatEstimasi(estimasi)}",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),

              const SizedBox(height: 6),

              Text(
                "Status: ${status?.toString() ?? "-"}",
                style: TextStyle(
                  fontSize: 14,
                  color: getStatusColor(status),
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "Prediksi Perbaikan:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 6),

              if (prediksiPerbaikan is List)
                ...prediksiPerbaikan.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      "• $item",
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                    ),
                  ),
                )
              else
                const Text(
                  "-",
                  style: TextStyle(fontSize: 13, color: Colors.black),
                ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A59BA),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: isPredicting ? null : runPrediction,
                  icon: isPredicting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.analytics, color: Colors.white),
                  label: Text(
                    isPredicting ? "Memproses..." : "Jalankan Prediksi ML",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: isPredicting ? null : createDummyAndRunPrediction,
                  icon: const Icon(Icons.add_box, color: Colors.white),
                  label: const Text(
                    "Buat Dummy + Simpan RUL",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final kendaraan = widget.kendaraan;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          kendaraan['plat_kendaraan'] ?? 'Detail Kendaraan',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF0B4996),
      ),
      backgroundColor: const Color(0xFF0B4996),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            predictionCard(),

            detailItem("ID Kendaraan", widget.kendaraanId),
            detailItem("Plat Kendaraan", kendaraan['plat_kendaraan']),
            detailItem("Model Kendaraan", kendaraan['model_kendaraan']),
            detailItem("Jenis Kendaraan", "Truck"),
            detailItem("Tahun Produksi", kendaraan['tahun_produksi']),
            detailItem("Kapasitas Muatan", kendaraan['kapasitas_muatan']),
            detailItem("Total Jam Operasi", kendaraan['total_jam_operasi']),
            detailItem("Estimasi Masa Pakai", kendaraan['estimasi_masa_pakai']),
            detailItem("Status RUL", kendaraan['status_rul']),
          ],
        ),
      ),
    );
  }
}
