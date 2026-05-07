import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseRangeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getPerjalananByRange({
    required String kendaraanId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = Timestamp.fromDate(startDate);

    // endDate dibuat +1 hari agar tanggal akhir ikut terambil penuh
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

    return snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }
}
