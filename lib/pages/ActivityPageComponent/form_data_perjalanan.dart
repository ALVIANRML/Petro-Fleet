// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pertro_fleet/pages/fungsi/RupiahInputFormatter.dart';

class FormDataPerjalanan extends StatefulWidget {
  final String? docId;
  final String? kendaraanId;
  final Map<String, dynamic>? data;
  const FormDataPerjalanan({
    super.key,
    this.docId,
    this.kendaraanId,
    this.data,
  });

  @override
  State<FormDataPerjalanan> createState() => _FormDataPerjalananState();
}

class _FormDataPerjalananState extends State<FormDataPerjalanan> {
  bool get isEdit => widget.docId != null;
  String? selectedPlat;
  final TextEditingController muatanController = TextEditingController();
  final TextEditingController lokasiAwalController = TextEditingController();
  final TextEditingController tujuanMuatanController = TextEditingController();
  final TextEditingController upahDriverController = TextEditingController();
  final TextEditingController uangBensinController = TextEditingController();
  final TextEditingController tanggalBerangkatController =
      TextEditingController();
  final rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Stream<List<String>> getPlatKendaraan() {
    return FirebaseFirestore.instance.collection('kendaraan').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return doc['plat_kendaraan'] as String;
      }).toList();
    });
  }

  Future<void> submitFunction(BuildContext context) async {
    if (selectedPlat == null ||
        muatanController.text.isEmpty ||
        lokasiAwalController.text.isEmpty ||
        tujuanMuatanController.text.isEmpty ||
        upahDriverController.text.isEmpty ||
        uangBensinController.text.isEmpty ||
        tanggalBerangkatController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua field wajib diisi")));
      return;
    }

    try {
      final data = {
        'jumlah_muatan': int.parse(muatanController.text.replaceAll('.', '')),
        'lokasi_awal': lokasiAwalController.text,
        'tujuan_muatan': tujuanMuatanController.text,
        'upah_driver': int.parse(upahDriverController.text.replaceAll('.', '')),
        'uang_bensin': int.parse(uangBensinController.text.replaceAll('.', '')),
        'tanggal': tanggalBerangkatController.text,
      };

      if (isEdit) {
        // UPDATE
        await FirebaseFirestore.instance
            .collection('kendaraan')
            .doc(widget.kendaraanId)
            .collection('perjalanan')
            .doc(widget.docId)
            .update(data);
      } else {
        // ADD
        await FirebaseFirestore.instance
            .collection('kendaraan')
            .doc(selectedPlat)
            .collection('perjalanan')
            .add({
              ...data,
              'created_at': FieldValue.serverTimestamp(),
              'total_muatan_diterima': 0,
              'tanggal_tiba': null,
              'status': "in transit",
            });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? "Data berhasil diupdate" : "Data berhasil ditambahkan",
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (context.mounted) {
          Navigator.pop(context, true);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void initState() {
    super.initState();

    if (isEdit && widget.data != null) {
      final data = widget.data!;

      selectedPlat = widget.kendaraanId;

      muatanController.text = data['jumlah_muatan']?.toString() ?? '';

      lokasiAwalController.text = data['lokasi_awal'] ?? '';

      tujuanMuatanController.text = data['tujuan_muatan'] ?? '';

      upahDriverController.text = data['upah_driver']?.toString() ?? '';

      uangBensinController.text = data['uang_bensin']?.toString() ?? '';

      tanggalBerangkatController.text = data['tanggal'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B4996),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B4996),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? "Edit Data Perjalanan" : "Input Data Perjalanan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plat Kendaraan
            const Text("Plat Kendaraan", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('kendaraan')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("Tidak ada data");
                }
                final platList = snapshot.data!.docs.map((doc) {
                  return {
                    'id': doc.id,
                    'plat': doc['plat_kendaraan']?.toString().trim() ?? '-',
                  };
                }).toList();
                return DropdownButtonFormField<String>(
                  initialValue: platList.any((e) => e['id'] == selectedPlat)
                      ? selectedPlat
                      : null,
                  dropdownColor: const Color(0xFFFFFFFF),
                  decoration: _inputDecoration("Pilih Plat Kendaraan"),
                  style: const TextStyle(color: Colors.black),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  items: platList.map((plat) {
                    return DropdownMenuItem(
                      value: plat['id'],
                      child: Text(plat['plat'] ?? '-'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedPlat = val),
                );
              },
            ),
            const SizedBox(height: 16),

            // Jumlah Muatan
            const Text(
              "Jumlah Muatan (Liter)",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: muatanController,
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
            const SizedBox(height: 16),

            // lokasi awal muatan
            const Text(
              "Lokasi Awal Muatan",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: lokasiAwalController,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration("Masukkan Lokasi Awal Muatan"),
            ),
            const SizedBox(height: 16),

            // Tujuan muatan
            const Text("Tujuan Muatan", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: tujuanMuatanController,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration("Masukkan Tujuan Muatan"),
            ),
            const SizedBox(height: 16),

            // Upah Driver
            const Text(
              "Upah Driver (Rp)",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: upahDriverController,
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration("Masukkan Upah Driver (Rp)")
                  .copyWith(
                    prefixText: "Rp ",
                    prefixStyle: const TextStyle(color: Colors.black),
                  ),
            ),
            const SizedBox(height: 16),

            // Uang Bensin
            const Text(
              "Uang Bensin (Rp)",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: uangBensinController,
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration("Masukkan Uang Bensin (Rp)")
                  .copyWith(
                    prefixText: "Rp ",
                    prefixStyle: const TextStyle(color: Colors.black),
                  ),
            ),
            const SizedBox(height: 16),

            // Tanggal Berangkat
            const Text(
              "Tanggal Keberangkatan",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),

            TextField(
              readOnly: true,
              controller: tanggalBerangkatController,
              style: const TextStyle(color: Colors.black),
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
                    tanggalBerangkatController.text = DateFormat(
                      'dd-MM-yyyy',
                    ).format(pickedDate);
                  });
                }
              },
            ),
            const SizedBox(height: 30),

            // Tombol Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final confirm = await showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text("Konfirmasi"),
                      content: Text(
                        isEdit
                            ? "Apakah anda yakin ingin mengubah data?"
                            : "Apakah anda yakin ingin menambahkan data?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text("Batal"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text("Ya"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    submitFunction(context);
                  }
                },
                child: Text(
                  isEdit ? "Update Data" : "Tambahkan Data",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF000000),
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
