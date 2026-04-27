import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pertro_fleet/pages/ActivityPageComponent/activity_detail_service.dart';
import 'package:pertro_fleet/pages/main_dashboard_page.dart';
import 'package:pertro_fleet/pages/ActivityPageComponent/form_data_service.dart';

class DataServicePage extends StatefulWidget {
  const DataServicePage({super.key});

  @override
  DataServicePageState createState() => DataServicePageState();
}

class DataServicePageState extends State<DataServicePage> {
  DateTime? selectedDate;
  String searchQuery = '';
  Future<List<Map<String, dynamic>>> getServiceData() async {
    final kendaraanSnapshot = await FirebaseFirestore.instance
        .collection('kendaraan')
        .get();
    final List<Map<String, dynamic>> allData = [];

    for (final kendaraan in kendaraanSnapshot.docs) {
      final plat = kendaraan['plat_kendaraan'];

      final serviceSnapshot = await kendaraan.reference
          .collection('service')
          .get();

      for (final doc in serviceSnapshot.docs) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B4996),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardPage(initialIndex: 2),
              ),
            );
          },
        ),
        title: const Text(
          "Data Service",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF0B4996),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10), // jarak dari atas

            Align(
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Cari...",
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

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFF0A59BA),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FormDataService(),
                        ),
                      ),
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
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                    "Tanggal ",
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
                    "Perbaikan",
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
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: getServiceData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Terjadi Error: ${snapshot.error}",
                        style: TextStyle(color: Colors.white),
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
                              final tglRaw = data['tanggal_perbaikan'];

                              // ✅ kalau Timestamp
                              if (tglRaw is Timestamp) {
                                final d = tglRaw.toDate();

                                return d.day == selectedDate!.day &&
                                    d.month == selectedDate!.month &&
                                    d.year == selectedDate!.year;
                              }

                              // ✅ kalau String (format: 27-4-2026)
                              if (tglRaw is String) {
                                try {
                                  final parts = tglRaw.split('-');
                                  if (parts.length == 3) {
                                    final d = DateTime(
                                      int.parse(parts[2]), // year
                                      int.parse(parts[1]), // month
                                      int.parse(parts[0]), // day
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

                        return bTime.compareTo(aTime); // 🔥 terbaru di atas
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
                      final tanggal = data['tanggal_perbaikan'] ?? '-';
                      final jenisService = data['jenis_kerusakan'] ?? '-';
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
                                    jenisService,
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
                                              DetailServicePage(
                                                docId: docId,
                                                kendaraanId: kendaraanId,
                                                data: data,
                                              ),
                                        ),
                                      ).then((_) {
                                        // Refresh data setelah kembali dari detail
                                        setState(() {});
                                      });
                                    },
                                  ),
                                ),
                              ],
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
}
