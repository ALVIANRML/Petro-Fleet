import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseRangeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getPerjalananByRange({
    required String kendaraanId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = Timestamp.fromDate(startDate);

    final end = Timestamp.fromDate(
      DateTime(endDate.year, endDate.month, endDate.day + 1),
    );

    final snapshot = await _firestore
        .collection('kendaraan')
        .doc(kendaraanId)
        .collection('perjalanan')
        .where('tanggal', isGreaterThanOrEqualTo: start)
        .where('tanggal', isLessThan: end)
        .orderBy('tanggal')
        .get();
    print("Jumlah data perjalanan: ${snapshot.docs.length}");

    for (var doc in snapshot.docs) {
      print("ID: ${doc.id}");
      print(doc.data());
    }

    return snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getServiceByRange({
    required String kendaraanId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = Timestamp.fromDate(startDate);

    final end = Timestamp.fromDate(
      DateTime(endDate.year, endDate.month, endDate.day + 1),
    );

    final snapshot = await _firestore
        .collection('kendaraan')
        .doc(kendaraanId)
        .collection('service')
        .where('tanggal_perbaikan', isGreaterThanOrEqualTo: start)
        .where('tanggal_perbaikan', isLessThan: end)
        .orderBy('tanggal_perbaikan')
        .get();

    print("Jumlah data service: ${snapshot.docs.length}");

    for (var doc in snapshot.docs) {
      print("ID: ${doc.id}");
      print(doc.data());
    }

    return snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }
}

Map<String, dynamic>? getLastServiceBeforeDate(
  DateTime perjalananDate,
  List<Map<String, dynamic>> services,
) {
  Map<String, dynamic>? selectedService;

  for (final service in services) {
    final serviceDate = (service['tanggal_perbaikan'] as Timestamp).toDate();

    if (serviceDate.isBefore(perjalananDate) ||
        serviceDate.isAtSameMomentAs(perjalananDate)) {
      selectedService = service;
    } else {
      break;
    }
  }

  return selectedService;
}

