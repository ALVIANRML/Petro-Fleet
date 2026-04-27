import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:pertro_fleet/pages/ActivityPageComponent/form_data_service.dart';

class DetailServicePage extends StatefulWidget {
  final String docId;
  final String kendaraanId;
  final Map<String, dynamic> data;

  const DetailServicePage({
    super.key,
    required this.docId,
    required this.kendaraanId,
    required this.data,
  });
  @override
  State<DetailServicePage> createState() => _DetailServicePageState();
}

class _DetailServicePageState extends State<DetailServicePage> {
  String formatRupiah(dynamic value) {
    final num = int.tryParse(value.toString()) ?? 0;
    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Color getKondisiColor(String? kondisi) {
    switch (kondisi) {
      case 'Baik':
        return Colors.green;
      case 'Sedang':
        return Colors.orange;
      case 'Buruk':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  DocumentReference get docRef => FirebaseFirestore.instance
      .collection('kendaraan')
      .doc(widget.kendaraanId)
      .collection('service')
      .doc(widget.docId);

  Future<void> hapusData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Yakin ingin menghapus data service ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await docRef.delete();
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platKendaraan = widget.data['plat_kendaraan'] ?? '-';
    final tanggal = widget.data['tanggal_perbaikan'] ?? '-';
    final jenis_kerusakan = widget.data['jenis_kerusakan'] ?? '-';
    final biayaService = widget.data['biaya_service'] ?? 0;
    final kondisiRem = widget.data['kondisi_rem'] ?? '-';
    final kondisiBan = widget.data['kondisi_ban'] ?? '-';
    final kondisiBaterai = widget.data['kondisi_baterai'] ?? '-';
    final kecelakaan = widget.data['kecelakaan'] ?? '-';
    final catatanKecelakaan = widget.data['catatan_kecelakaan'] ?? '-';
    final odometerService = widget.data['odometer_service'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B4996),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B4996),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Detail Service',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Plat Kendaraan:'),
            _value(platKendaraan),
            const SizedBox(height: 10),
            _label('Tanggal Berangkat:'),
            _value(tanggal),
            const SizedBox(height: 10),
            _label('Jenis Service:'),
            _value(jenis_kerusakan),
            const SizedBox(height: 10),
            _label('Biaya Service:'),
            _value('Rp ${formatRupiah(biayaService)}'),
            _label('Odometer Saat Service:'),
            _value('${formatRupiah(odometerService)} KM'),
            const SizedBox(height: 10),
            _label('Kondisi Rem:'),
            _value(kondisiRem),
            const SizedBox(height: 10),
            _label('Kondisi Ban:'),
            _value(kondisiBan),
            const SizedBox(height: 10),
            _label('Kondisi Baterai:'),
            _value(kondisiBaterai),
            const SizedBox(height: 10),
            _label('Terjai Kecelakaan:'),
            _value(kecelakaan),
            const SizedBox(height: 10),
            _label('Catatan Kecelakaan:'),
            _value(catatanKecelakaan),
            const SizedBox(height: 10),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FormDataService(
                            docId: widget.docId,
                            kendaraanId: widget.kendaraanId,
                            data: widget.data,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Edit",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => hapusData(context),
                    child: const Text(
                      "Hapus",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  );

  Widget _value(String? text) {
    return Text(text ?? '-', style: TextStyle(color: getKondisiColor(text)));
  }
}
