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

  double getDoubleValue(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    final result = double.tryParse(
      value.toString().trim().replaceAll(',', '.'),
    );
    return result ?? defaultValue;
  }

  int getIntValue(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  final FirebaseRangeService rangeService = FirebaseRangeService();

  final RulApiService rulApiService = RulApiService(
    baseUrl: 'http://10.0.2.2:5000',
  );

  int dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  Color getStatusColor(dynamic status) {
    final text = status?.toString() ?? '';
    if (text.contains('Hijau')) return Colors.green;
    if (text.contains('Jingga')) return Colors.orange;
    if (text.contains('Merah')) return Colors.red;
    return Colors.black;
  }

 
  double _hitungActualLoad(Map<String, dynamic> perjalanan) {

    final totalField = getDoubleValue(perjalanan['total_jumlah_muatan']);
    if (totalField > 0) return totalField;


    if (perjalanan['muatan'] is List) {
      double total = 0.0;
      for (final item in perjalanan['muatan'] as List) {
        if (item is Map<String, dynamic>) {
          total += getDoubleValue(item['jumlah_muatan']);
        }
      }
      if (total > 0) return total;
    }

    return 0.0;
  }

  double _hitungUsageHours(Map<String, dynamic> perjalanan) {
    final usageHours = getDoubleValue(perjalanan['usage_hours']);
    if (usageHours > 0) return usageHours;

    final jarakKm = getDoubleValue(perjalanan['jarak_km']);
    if (jarakKm > 0) return jarakKm / 40.0;

    return 0.0;
  }

  Map<String, dynamic> buildObservation({
    required Map<String, dynamic> kendaraan,
    required Map<String, dynamic> perjalanan,
    required Map<String, dynamic>? service,
    required int recordNo,
    required int elapsedDays,
  }) {
    final tahunProduksi = getIntValue(
      kendaraan['tahun_produksi'],
      defaultValue: 2020,
    );
    final loadCapacity = getDoubleValue(
      kendaraan['kapasitas_muatan'],
      defaultValue: 0.0,
    );
    print("ini perjalanan $perjalanan");
    final usageHours = _hitungUsageHours(perjalanan);
    final actualLoad = _hitungActualLoad(perjalanan);

    final tanggalRaw = perjalanan['tanggal'];
    final tanggal = tanggalRaw is Timestamp
        ? tanggalRaw.toDate()
        : DateTime.now();

    final jarakKm = getDoubleValue(perjalanan['jarak_km']);
    final uangBensin = getDoubleValue(perjalanan['uang_bensin']);

    final brakeCondition = getDoubleValue(
      service?['brake_condition'],
      defaultValue: 0.0,
    );
    final batteryStatus = getDoubleValue(
      service?['battery_status'],
      defaultValue: 0.0,
    );
    final tirePressure = getDoubleValue(
      service?['tire_preasure'],
      defaultValue: 0.0,
    );
  
    final fuelConsumption = getDoubleValue(
      service?['fuel_consumption'] ?? service?['fuel_consumtion'],
      defaultValue: 0.0,
    );

    final vibrationLevel = getDoubleValue(
      service?['vibration_level'],
      defaultValue: 0.0,
    );
    final oilQuality = getDoubleValue(
      service?['oil_quality'],
      defaultValue: 0.0,
    );

    final kecelakaan = service?['kecelakaan']?.toString().toLowerCase() ?? '';
    final catatanKerusakan =
        service?['catatan_kerusakan']?.toString().toLowerCase() ?? '';
    final failureHistory =
        kecelakaan == 'ya' ||
            (catatanKerusakan != '-' && catatanKerusakan.isNotEmpty)
        ? 1
        : 0;

    return {
      'Record_No': recordNo,
      'Year_of_Manufacture': tahunProduksi,
      'Usage_Hours': usageHours,
      'Load_Capacity': loadCapacity,
      'Actual_Load': actualLoad,
      'Engine_Temperature': 50,
      'Tire_Pressure': tirePressure,
      'Fuel_Consumption': fuelConsumption,
      'Battery_Status': batteryStatus,
      'Vibration_Levels': vibrationLevel,
      'Oil_Quality': oilQuality,
      'Failure_History': failureHistory,
      'Anomalies_Detected': service != null ? 1 : 0,
      'Delivery_Times': 60,
      'Elapsed_Days': elapsedDays,
      'Days_Since_Last_Observation': 1,
      'Observation_Month': tanggal.month,
      'Observation_DayOfYear': dayOfYear(tanggal),
      'Route_Info_Rural': 0,
      'Route_Info_Urban': 1,
      'Brake_Condition_Good': brakeCondition >= 80 ? 1 : 0,
      'Brake_Condition_Poor': brakeCondition <= 40 ? 1 : 0,
      'Weather_Conditions_Rainy': 0,
      'Weather_Conditions_Snowy': 0,
      'Weather_Conditions_Windy': 0,
      'Road_Conditions_Rural': 0,
      'Road_Conditions_Urban': 1,

      'Tanggal_Perjalanan': tanggal.toIso8601String(),
      'Jarak_KM': jarakKm,
      'Total_Muatan': actualLoad,
      'Uang_Bensin': uangBensin,
    };
  }

  Future<void> runPrediction() async {
    try {
      setState(() => isPredicting = true);

      final startDate = DateTime(2000, 1, 1);
      final endDate = DateTime(2100, 12, 31);

      final perjalanan = await rangeService.getPerjalananByRange(
        kendaraanId: widget.kendaraanId,
        startDate: startDate,
        endDate: endDate,
      );
      print("Jumlah perjalanan: ${perjalanan.length}");

      final service = await rangeService.getServiceByRange(
        kendaraanId: widget.kendaraanId,
        startDate: startDate,
        endDate: endDate,
      );
      print("Jumlah service: ${service.length}");

      if (perjalanan.isEmpty && service.isEmpty) {
        throw Exception("Tidak ada data perjalanan/service.");
      }

      Map<String, dynamic>? getServiceTerakhir(DateTime tanggalPerjalanan) {
        Map<String, dynamic>? hasil;
        for (final s in service) {
          final tanggalService = (s['tanggal_perbaikan'] as Timestamp).toDate();
          if (!tanggalService.isAfter(tanggalPerjalanan)) {
            hasil = s;
          } else {
            break;
          }
        }
        return hasil;
      }

      final List<Map<String, dynamic>> observations = [];

      for (int i = 0; i < perjalanan.length; i++) {
        final p = perjalanan[i];
        final tanggalPerjalanan = (p['tanggal'] as Timestamp).toDate();
        final serviceTerakhir = getServiceTerakhir(tanggalPerjalanan);

        final obs = buildObservation(
          kendaraan: widget.kendaraan,
          perjalanan: p,
          service: serviceTerakhir,
          recordNo: i + 1,
          elapsedDays: i,
        );
        observations.add(obs);
      }


      for (int i = 0; i < observations.length; i++) {
        final obs = observations[i];
      }


      if (observations.length < 3) {
        throw Exception(
          "Data perjalanan kurang: ${observations.length} observasi. "
          "Butuh minimal 3 perjalanan agar model LSTM bisa membuat prediksi.",
        );
      }
      final result = await rulApiService.predictRul(observations);

      final prediksiRulHari = (result['prediksi_rul_hari'] as num).toDouble();
      final status = result['status'].toString();
      final prediksiKerusakan =
          result['prediksi_maintenance']?.toString() ?? '-';

      await FirebaseFirestore.instance
          .collection('kendaraan')
          .doc(widget.kendaraanId)
          .set({
            'estimasi_masa_pakai': prediksiRulHari,
            'rul_hari': prediksiRulHari,
            'status_rul': status,
            'prediksi_kerusakan': prediksiKerusakan,
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
            'tanggal_mulai': Timestamp.fromDate(startDate),
            'tanggal_selesai': Timestamp.fromDate(endDate),
            'created_at': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Prediksi berhasil: ${prediksiRulHari.toStringAsFixed(2)} hari — $status — $prediksiKerusakan",
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
      if (mounted) setState(() => isPredicting = false);
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
        final prediksiKerusakan = data?['prediksi_kerusakan'];

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
                "Estimasi Sisa Pakai: ${estimasi != null ? (estimasi as num).round() : 0} hari",
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
                    isPredicting ? "Memproses..." : "Lakukan Prediksi",
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
          ],
        ),
      ),
    );
  }
}
