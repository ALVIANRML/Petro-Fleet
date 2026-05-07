import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pertro_fleet/pages/ActivityPageComponent/activity_detail_perjalanan.dart';

class HistoryPekerjaanPage extends StatefulWidget {
  const HistoryPekerjaanPage({super.key});

  @override
  State<HistoryPekerjaanPage> createState() => _HistoryPekerjaanPageState();
}

class _HistoryPekerjaanPageState extends State<HistoryPekerjaanPage> {
  final user = FirebaseAuth.instance.currentUser;
  String searchQuery = '';
  DateTime? selectedDate;

  // Helper untuk format Timestamp ke string
  String formatTanggal(dynamic value) {
    if (value == null) return '-';
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    }
    if (value is String) return value;
    return '-';
  }

  // Pastikan GPS aktif sebelum detail perjalanan
  Future<bool> _ensureLocationReady(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return false;
      await Geolocator.openLocationSettings();
      await Future.delayed(const Duration(seconds: 2));
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  // Ambil data perjalanan dari Firestore berdasarkan id_pengemudi
  Future<List<Map<String, dynamic>>> getPerjalananData() async {
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('perjalanan')
        .where('id_pengemudi', isEqualTo: user!.uid)
        .orderBy('tanggal', descending: true)
        .get();

    final List<Map<String, dynamic>> result = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final kendaraanRef = doc.reference.parent.parent;

      String platKendaraan = '-';
      if (kendaraanRef != null) {
        final kendaraanDoc = await kendaraanRef.get();
        platKendaraan = kendaraanDoc.data()?['plat_kendaraan'] ?? '-';
      }

      result.add({
        'id': doc.id,
        'kendaraan_id': kendaraanRef?.id,
        'plat_kendaraan': platKendaraan,
        ...data,
      });
    }

    return result;
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B4996),
      appBar: AppBar(
        title: const Text(
          "History Pekerjaan",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B4996),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date picker
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => pickDate(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A59BA),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate == null
                          ? "Pilih Tanggal"
                          : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (selectedDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDate = null;
                          });
                        },
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header tabel
            Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    "Plat Kendaraan",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Tanggal",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Tujuan",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Aksi",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white),

            // List data perjalanan
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: getPerjalananData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Terjadi Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "Tidak Ada Data",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final docs =
                      snapshot.data!.where((data) {
                        final plat = (data['plat_kendaraan'] ?? '')
                            .toString()
                            .toLowerCase();
                        final matchSearch =
                            searchQuery.isEmpty || plat.contains(searchQuery);
                        final matchDate =
                            selectedDate == null ||
                            (() {
                              final tglRaw = data['tanggal'];
                              if (tglRaw is Timestamp) {
                                final d = tglRaw.toDate();
                                return d.day == selectedDate!.day &&
                                    d.month == selectedDate!.month &&
                                    d.year == selectedDate!.year;
                              }
                              if (tglRaw is String) {
                                try {
                                  final parts = tglRaw.split('-');
                                  if (parts.length == 3) {
                                    final d = DateTime(
                                      int.parse(parts[2]),
                                      int.parse(parts[1]),
                                      int.parse(parts[0]),
                                    );
                                    return d.day == selectedDate!.day &&
                                        d.month == selectedDate!.month &&
                                        d.year == selectedDate!.year;
                                  }
                                } catch (_) {
                                  return false;
                                }
                              }
                              return false;
                            })();
                        return matchSearch && matchDate;
                      }).toList()..sort((a, b) {
                        final aTime = a['created_at'] as Timestamp?;
                        final bTime = b['created_at'] as Timestamp?;
                        if (aTime == null || bTime == null) return 0;
                        return bTime.compareTo(aTime);
                      });

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index];
                      final platKendaraan = data['plat_kendaraan'] ?? '-';
                      final tanggal = formatTanggal(data['tanggal']);
                      final tujuan = data['tujuan_muatan'] ?? '-';
                      final docId = data['id'] ?? '';
                      final kendaraanId = data['kendaraan_id'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A3A7A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                platKendaraan,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                tanggal,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                tujuan,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  final locationReady =
                                      await _ensureLocationReady(context);
                                  if (!locationReady) return;
                                  if (!context.mounted) return;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetailPerjalananPage(
                                            docId: docId,
                                            currentStatus: 'history',
                                            kendaraanId: kendaraanId,
                                            data: data,
                                          ),
                                    ),
                                  ).then((_) => setState(() {}));
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
