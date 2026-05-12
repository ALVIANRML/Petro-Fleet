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

  final FirebaseRangeService rangeService = FirebaseRangeService();

  final RulApiService rulApiService = RulApiService(
    //base url hp bisa berganti ganti
    baseUrl: 'http://192.168.100.4:5000',

    // base url emulator
    // baseUrl: 'http://10.0.2.2:5000',
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

      // Tambahan untuk model Maintenance Type
      'Weather_Conditions_Rainy': 0,
      'Weather_Conditions_Snowy': 0,
      'Weather_Conditions_Windy': 0,

      'Road_Conditions_Rural': 0,
      'Road_Conditions_Urban': 1,
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

      // Tambahan untuk prediksi Maintenance Type
      'Weather_Conditions_Rainy': data['Weather_Conditions_Rainy'] ?? 0,
      'Weather_Conditions_Snowy': data['Weather_Conditions_Snowy'] ?? 0,
      'Weather_Conditions_Windy': data['Weather_Conditions_Windy'] ?? 0,
      'Road_Conditions_Rural': data['Road_Conditions_Rural'] ?? 0,
      'Road_Conditions_Urban': data['Road_Conditions_Urban'] ?? 1,
    };
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

      final prediksiKerusakan =
          result['prediksi_maintenance']?.toString() ?? '-';

      final confidenceMaintenance = result['confidence_maintenance'] is num
          ? (result['confidence_maintenance'] as num).toDouble()
          : 0.0;

      await FirebaseFirestore.instance
          .collection('kendaraan')
          .doc(widget.kendaraanId)
          .set({
            'estimasi_masa_pakai': prediksiRulHari,
            'rul_hari': prediksiRulHari,
            'status_rul': status,
            'prediksi_kerusakan': prediksiKerusakan,
            'confidence_maintenance': confidenceMaintenance,
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
            'prediksi_kerusakan': prediksiKerusakan,
            'confidence_maintenance': confidenceMaintenance,
            'tanggal_mulai': Timestamp.fromDate(startDate),
            'tanggal_selesai': Timestamp.fromDate(endDate),
            'created_at': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Prediksi berhasil: ${prediksiRulHari.toStringAsFixed(2)} hari - $status - $prediksiKerusakan",
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

  Widget detailItem(
    String title,
    dynamic value, {
    Color valueColor = Colors.black,
  }) {
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
        final prediksiKerusakan = data?['prediksi_kerusakan'];
        final confidenceMaintenance = data?['confidence_maintenance'];

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
                "Estimasi Sisa Pakai: ${estimasi?.round() ?? 0} hari",
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
                "Prediksi Kerusakan/Perawatan:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                prediksiKerusakan?.toString() ?? "-",
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Confidence: ${confidenceMaintenance is num ? (confidenceMaintenance * 100).toStringAsFixed(2) : "0.00"}%",
                style: const TextStyle(fontSize: 13, color: Colors.black54),
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
            detailItem(
              "Status RUL",
              kendaraan['status_rul'],
              valueColor: getStatusColor(kendaraan['status_rul']),
            ),
          ],
        ),
      ),
    );
  }
}
