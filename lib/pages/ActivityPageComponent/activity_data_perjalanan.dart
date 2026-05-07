import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pertro_fleet/pages/ActivityPageComponent/activity_detail_perjalanan.dart';
import 'package:pertro_fleet/pages/ActivityPageComponent/form_data_perjalanan.dart';
import 'package:pertro_fleet/pages/main_dashboard_page.dart';

class DataPerjalananPage extends StatefulWidget {
  const DataPerjalananPage({super.key});

  @override
  DataPerjalananPageState createState() => DataPerjalananPageState();
}

class DataPerjalananPageState extends State<DataPerjalananPage> {
  /// 0 = in_transit, 1 = on_trip, 2 = completed
  int selectedTab = 0;
  DateTime? selectedDate;
  String searchQuery = '';

  String get statusTarget {
    switch (selectedTab) {
      case 0:
        return 'in_transit';
      case 1:
        return 'on_trip';
      case 2:
        return 'completed';
      default:
        return 'in_transit';
    }
  }

  String formatTanggal(dynamic value) {
    if (value == null) return '-';

    if (value is Timestamp) {
      final date = value.toDate();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      return '$day-$month-$year';
    }

    return value.toString();
  }

  String formatAngka(dynamic value) {
    final num = int.tryParse(value.toString()) ?? 0;
    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
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

  Future<List<Map<String, dynamic>>> getPerjalananData() async {
    final kendaraanSnapshot = await FirebaseFirestore.instance
        .collection('kendaraan')
        .get();

    final List<Map<String, dynamic>> allData = [];

    for (final kendaraan in kendaraanSnapshot.docs) {
      final plat = kendaraan['plat_kendaraan'];

      final perjalananSnapshot = await kendaraan.reference
          .collection('perjalanan')
          .where('status', isEqualTo: statusTarget)
          .get();

      for (final doc in perjalananSnapshot.docs) {
        allData.add({
          'id': doc.id,
          'kendaraan_id': kendaraan.id,
          'plat_kendaraan': plat,
          ...doc.data(),
        });
      }
    }

    return allData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B4996),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DashboardPage(initialIndex: 2),
            ),
          ),
        ),
        title: const Text(
          "Data Perjalanan",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B4996),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Search bar
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Cari....",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.black),
            ),

            const SizedBox(height: 10),

            // Tombol Tambah Data
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF0A59BA),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FormDataPerjalanan(),
                    ),
                  ).then((result) {
                    if (result == true) setState(() {});
                  });
                },
                child: const Text(
                  "+ Tambah Data",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Tombol Pilih Tanggal
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

            const SizedBox(height: 10),

            // ── Toggle 3 tab: In Transit | On Trip | Completed ──
            Row(
              children: [
                _tabButton(
                  label: 'In Transit',
                  index: 0,
                  activeColor: const Color(0xFFFF9D00),
                  inactiveColor: const Color(0xFFB87300),
                ),
                const SizedBox(width: 2),
                _tabButton(
                  label: 'On Trip',
                  index: 1,
                  activeColor: const Color(0xFF3A8BF0),
                  inactiveColor: const Color(0xFF1A4A80),
                ),
                const SizedBox(width: 2),
                _tabButton(
                  label: 'Completed',
                  index: 2,
                  activeColor: const Color(0xFF00DB21),
                  inactiveColor: const Color(0xFF376D3F),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Header tabel
            const Row(
              children: [
                Expanded(
                  flex: 3,
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
                  flex: 3,
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
                    "Muatan",
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

            // List data dari Firestore
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
                        "Terjadi error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "Tidak ada data",
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
                                } catch (e) {
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

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Tidak ada data yang cocok",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index];
                      final platKendaraan = data['plat_kendaraan'] ?? '-';
                      final tanggal = formatTanggal(data['tanggal']);
                      final jumlahMuatan = data['total_jumlah_muatan'] ?? 0;
                      final lokasi = data['lokasi_awal'] ?? '-';
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
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    platKendaraan,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    tanggal,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "${formatAngka(jumlahMuatan)} Kg",
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
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DetailPerjalananPage(
                                                currentStatus: statusTarget,
                                                docId: docId,
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
                            const SizedBox(height: 4),
                            Text(
                              "$lokasi → $tujuan",
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const Divider(color: Colors.white24),
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

  Widget _tabButton({
    required String label,
    required int index,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isActive = selectedTab == index;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          backgroundColor: isActive ? activeColor : inactiveColor,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        onPressed: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
