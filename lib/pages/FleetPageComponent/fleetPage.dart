import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pertro_fleet/pages/FleetPageComponent/FormFleet.dart';
import 'package:pertro_fleet/pages/FleetPageComponent/fleetDetail_page.dart';

class FleetPage extends StatefulWidget {
  const FleetPage({super.key});

  @override
  State<FleetPage> createState() => _FleetPageState();
}

class _FleetPageState extends State<FleetPage> {
  String searchQuery = "";

  Stream<QuerySnapshot> getKendaraanStream() {
    return FirebaseFirestore.instance.collection('kendaraan').snapshots();
  }

  Color getStatusColor(dynamic status) {
    final text = status?.toString() ?? '';

    if (text.contains('Hijau')) return Colors.greenAccent;
    if (text.contains('Jingga')) return Colors.orangeAccent;
    if (text.contains('Merah')) return Colors.redAccent;

    return Colors.white;
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

  void goToDetail({
    required String kendaraanId,
    required Map<String, dynamic> kendaraan,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailFleetPage(
          kendaraanId: kendaraanId,
          kendaraan: kendaraan,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "FLEET",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B4996),
      ),
      backgroundColor: const Color(0xFF0B4996),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

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
                      hintStyle: const TextStyle(color: Colors.black),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black,
                      ),
                      filled: true,
                      fillColor: Colors.white,
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FormFleetPage(),
                          ),
                        );
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
                    "Jenis Kendaraan",
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
                    "Estimasi Sisa Pakai",
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
                    "Status",
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
              child: StreamBuilder<QuerySnapshot>(
                stream: getKendaraanStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Terjadi error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Data Kosong",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final data = snapshot.data!.docs;

                  final filteredData = data.where((doc) {
                    final kendaraan = doc.data() as Map<String, dynamic>;

                    final plat = (kendaraan['plat_kendaraan'] ?? "")
                        .toString()
                        .toLowerCase();

                    final model = (kendaraan['model_kendaraan'] ?? "")
                        .toString()
                        .toLowerCase();

                    return plat.contains(searchQuery) ||
                        model.contains(searchQuery);
                  }).toList();

                  if (filteredData.isEmpty) {
                    return const Center(
                      child: Text(
                        "Data tidak ditemukan",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final kendaraanId = filteredData[index].id;

                      final kendaraan =
                          filteredData[index].data() as Map<String, dynamic>;

                      final estimasi = kendaraan['estimasi_masa_pakai'];
                      final status = kendaraan['status_rul'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B4996),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    kendaraan['plat_kendaraan'] ?? "-",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    kendaraan['model_kendaraan'] ?? "-",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    formatEstimasi(estimasi),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: getStatusColor(status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          status?.toString() ?? "-",
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: getStatusColor(status),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          goToDetail(
                                            kendaraanId: kendaraanId,
                                            kendaraan: kendaraan,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white),
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