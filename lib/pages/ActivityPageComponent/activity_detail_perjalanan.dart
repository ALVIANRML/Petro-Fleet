import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:pertro_fleet/pages/fungsi/RupiahInputFormatter.dart';
import 'package:pertro_fleet/pages/ActivityPageComponent/form_data_perjalanan.dart';

class DetailPerjalananPage extends StatefulWidget {
  final bool isTransitSelected;
  final String docId;
  final String kendaraanId;
  final Map<String, dynamic> data;

  const DetailPerjalananPage({
    super.key,
    required this.isTransitSelected,
    required this.docId,
    required this.kendaraanId,
    required this.data,
  });
  @override
  State<DetailPerjalananPage> createState() => _DetailPerjalananPageState();
}

class _DetailPerjalananPageState extends State<DetailPerjalananPage> {
  final TextEditingController muatanDiterimaController =
      TextEditingController();
  final TextEditingController tanggalTibaController = TextEditingController();

  // Helper format rupiah
  String formatRupiah(dynamic value) {
    final num = int.tryParse(value.toString()) ?? 0;
    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  // Referensi dokumen yang benar: kendaraan/{id}/perjalanan/{docId}
  DocumentReference get docRef => FirebaseFirestore.instance
      .collection('kendaraan')
      .doc(widget.kendaraanId)
      .collection('perjalanan')
      .doc(widget.docId);

  Future<void> markAsCompleted(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Tandai perjalanan ini sebagai Completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (muatanDiterimaController.text.isEmpty) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Muatan diterima belum diisi")),
        );
        return;
      }

      if (tanggalTibaController.text.isEmpty) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tanggal tiba belum diisi")),
        );
        return;
      }

      await docRef.update({
        'status': 'completed',
        'total_muatan_diterima': int.parse(
          muatanDiterimaController.text.replaceAll('.', ''),
        ),
        'tanggal_tiba': tanggalTibaController.text, // atau Timestamp
      });

      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> hapusData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Yakin ingin menghapus data perjalanan ini?'),
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
    tanggalTibaController.dispose();
    muatanDiterimaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platKendaraan = widget.data['plat_kendaraan'] ?? '-';
    final tanggal = widget.data['tanggal'] ?? '-';
    final lokasi = widget.data['lokasi_awal'] ?? '-';
    final tujuan = widget.data['tujuan_muatan'] ?? '-';
    final upahDriver = widget.data['upah_driver'] ?? 0;
    final uangBensin = widget.data['uang_bensin'] ?? 0;
    final jumlahMuatan = widget.data['jumlah_muatan'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B4996),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B4996),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Detail Perjalanan',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: widget.isTransitSelected
                      ? Colors.orange
                      : const Color(0xFF00DB21),
                  borderRadius: BorderRadius.circular(200),
                ),
                child: Text(
                  widget.isTransitSelected ? 'In Transit' : 'Completed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _label('Plat Kendaraan:'),
            _value(platKendaraan),
            const SizedBox(height: 10),
            const SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_label('Tanggal Berangkat:'), _value(tanggal)],
                  ),
                ),
                const SizedBox(width: 20),
                if (!widget.isTransitSelected) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_label('Tanggal Sampai:'), _value(tanggal)],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),
            _label('Lokasi Awal:'),
            _value(lokasi),
            const Padding(
              padding: EdgeInsets.only(left: 30),
              child: Icon(Icons.arrow_downward, color: Colors.white),
            ),
            _label('Lokasi Akhir:'),
            _value(tujuan),
            const SizedBox(height: 10),

            _label('Upah Driver:'),
            _value('Rp ${formatRupiah(upahDriver)}'),
            const SizedBox(height: 10),

            _label('Uang Bensin:'),
            _value('Rp ${formatRupiah(uangBensin)}'),
            const SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Total Muatan:'),
                      _value("$jumlahMuatan L"),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                if (!widget.isTransitSelected) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Total Muatan:'),
                        _value("$jumlahMuatan L"),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            // Tombol aksi hanya muncul saat In Transit
            if (widget.isTransitSelected) ...[
              Text(
                "Muatan Diterima",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextField(
                controller: muatanDiterimaController,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  RupiahInputFormatter(),
                ],
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration(
                  "Masukkan Jumlah Muatan",
                ).copyWith(suffixText: "L"),
              ),
              SizedBox(height: 20),
              Text(
                "Tanggal Tiba",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                readOnly: true,
                controller: tanggalTibaController,
                decoration: _inputDecoration("Pilih Tanggal"),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (pickedDate != null) {
                    setState(() {
                      tanggalTibaController.text =
                          "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00DB21),
                  ),
                  onPressed: () => markAsCompleted(context),
                  child: const Text(
                    'Tandai Completed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A8BF0),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FormDataPerjalanan(
                          docId: widget.docId,
                          kendaraanId: widget.kendaraanId,
                          data: widget.data,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Edit Data',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0000),
                  ),
                  onPressed: () => hapusData(context),
                  child: const Text(
                    'Hapus Data',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  );

  Widget _value(String text) =>
      Text(text, style: const TextStyle(color: Colors.white));
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF000000),
      // ignore: deprecated_member_use
      ).copyWith(color: Color(0xFF000000).withOpacity(0.5)),
      filled: true,
      fillColor: const Color(0xFFD9D9D9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
