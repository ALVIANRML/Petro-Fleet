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
  String? selectedSupir;
  final TextEditingController jenisMuatanController = TextEditingController();
  final List<Map<String, TextEditingController>> muatanList = [];
  final TextEditingController lokasiAwalController = TextEditingController();
  final TextEditingController tujuanMuatanController = TextEditingController();
  final TextEditingController upahDriverController = TextEditingController();
  final TextEditingController uangBensinController = TextEditingController();
  final TextEditingController tanggalBerangkatController =
      TextEditingController();
  DateTime? selectedTanggalBerangkat;
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

  Stream<List<String>> getSupir() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('posisi', isEqualTo: 'Sopir') // ⬅️ filter di sini
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return doc['nama'] as String;
          }).toList();
        });
  }

  Future<void> submitFunction(BuildContext context) async {
    if (selectedPlat == null ||
        selectedSupir == null ||
        lokasiAwalController.text.isEmpty ||
        tujuanMuatanController.text.isEmpty ||
        upahDriverController.text.isEmpty ||
        uangBensinController.text.isEmpty ||
        selectedTanggalBerangkat == null ||
        muatanList.isEmpty ||
        muatanList.any(
          (m) => m['jenis']!.text.isEmpty || m['jumlah']!.text.isEmpty,
        )) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua field wajib diisi")));
      return;
    }

    try {
      print(selectedSupir);

      final muatanData = muatanList.map((m) {
        return {
          'jenis_muatan': m['jenis']!.text,
          'jumlah_muatan': int.parse(m['jumlah']!.text.replaceAll('.', '')),
        };
      }).toList();

      final totalMuatan = muatanData.fold<int>(
        0,
        (total, item) => total + (item['jumlah_muatan'] as int),
      );

      final data = {
        'muatan': muatanData,
        'total_jumlah_muatan': totalMuatan,
        'lokasi_awal': lokasiAwalController.text,
        'tujuan_muatan': tujuanMuatanController.text,
        'upah_driver': int.parse(upahDriverController.text.replaceAll('.', '')),
        'uang_bensin': int.parse(uangBensinController.text.replaceAll('.', '')),
        'tanggal': Timestamp.fromDate(selectedTanggalBerangkat!),
        'id_pengemudi': selectedSupir,
      };

      if (isEdit) {
        await FirebaseFirestore.instance
            .collection('kendaraan')
            .doc(widget.kendaraanId)
            .collection('perjalanan')
            .doc(widget.docId)
            .update(data);
      } else {
        await FirebaseFirestore.instance
            .collection('kendaraan')
            .doc(selectedPlat)
            .collection('perjalanan')
            .add({
              ...data,
              'created_at': FieldValue.serverTimestamp(),
              'total_muatan_diterima': 0,
              'tanggal_tiba': null,
              'status': 'in_transit',
              'approved_by_driver': false,
              'approved_arrival': false,
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
      selectedSupir = data['id_pengemudi'];

      lokasiAwalController.text = data['lokasi_awal'] ?? '';
      tujuanMuatanController.text = data['tujuan_muatan'] ?? '';
      upahDriverController.text = data['upah_driver']?.toString() ?? '';
      uangBensinController.text = data['uang_bensin']?.toString() ?? '';
      final tanggal = data['tanggal'];

      if (tanggal is Timestamp) {
        selectedTanggalBerangkat = tanggal.toDate();
        tanggalBerangkatController.text = DateFormat(
          'dd-MM-yyyy',
        ).format(selectedTanggalBerangkat!);
      } else if (tanggal is String) {
        tanggalBerangkatController.text = tanggal;
      }

      if (data['muatan'] != null && data['muatan'] is List) {
        for (var item in data['muatan']) {
          tambahMuatan(
            jenis: item['jenis_muatan']?.toString() ?? '',
            jumlah: item['jumlah_muatan']?.toString() ?? '',
          );
        }
      } else {
        tambahMuatan();
      }
    } else {
      tambahMuatan();
    }
  }

  void tambahMuatan({String jenis = '', String jumlah = ''}) {
    setState(() {
      muatanList.add({
        'jenis': TextEditingController(text: jenis),
        'jumlah': TextEditingController(text: jumlah),
      });
    });
  }

  void hapusMuatan(int index) {
    setState(() {
      muatanList[index]['jumlah']!.dispose();
      muatanList.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var item in muatanList) {
      item['jenis']!.dispose();
      item['jumlah']!.dispose();
    }

    lokasiAwalController.dispose();
    tujuanMuatanController.dispose();
    upahDriverController.dispose();
    uangBensinController.dispose();
    tanggalBerangkatController.dispose();

    super.dispose();
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
            const Text("Nama Pengemudi", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('posisi', isEqualTo: 'Sopir')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("Tidak ada data");
                }
                final pengemudiList = snapshot.data!.docs.map((doc) {
                  return {
                    'id': doc.id,
                    'nama_pengemudi': doc['nama']?.toString().trim() ?? '-',
                  };
                }).toList();
                return DropdownButtonFormField<String>(
                  initialValue:
                      pengemudiList.any((e) => e['id'] == selectedSupir)
                      ? selectedSupir
                      : null,
                  dropdownColor: const Color(0xFFFFFFFF),
                  decoration: _inputDecoration("Pilih Pengemudi"),
                  style: const TextStyle(color: Colors.black),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  items: pengemudiList.map((pengemudi) {
                    return DropdownMenuItem(
                      value: pengemudi['id'],
                      child: Text(pengemudi['nama_pengemudi'] ?? '-'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedSupir = val),
                );
              },
            ),
            SizedBox(height: 16),
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

            const Text(
              "Data Muatan",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Column(
              children: List.generate(muatanList.length, (index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Muatan ${index + 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (muatanList.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => hapusMuatan(index),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: muatanList[index]['jenis'],
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration("Masukkan Jenis Muatan"),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: muatanList[index]['jumlah'],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          RupiahInputFormatter(),
                        ],
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration(
                          "Masukkan Jumlah Muatan",
                        ).copyWith(suffixText: "Kg"),
                      ),
                    ],
                  ),
                );
              }),
            ),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => tambahMuatan(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Tambah Muatan",
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                ),
              ),
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
                  initialDate: selectedTanggalBerangkat ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (pickedDate != null) {
                  setState(() {
                    selectedTanggalBerangkat = pickedDate;

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
