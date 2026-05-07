import 'package:flutter/material.dart';
import 'package:pertro_fleet/pages/ActivityPageComponent/activity_data_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pertro_fleet/pages/fungsi/RupiahInputFormatter.dart';

class FormDataService extends StatefulWidget {
  final String? docId;
  final String? kendaraanId;
  final Map<String, dynamic>? data;

  const FormDataService({super.key, this.docId, this.kendaraanId, this.data});

  @override
  State<FormDataService> createState() => _FormDataServiceState();
}

class _FormDataServiceState extends State<FormDataService> {
  DateTime? selectedTanggalService;

  String? selectedPlat;
  String? selectedKondisiRem;
  String? selectedKondisiBaterai;
  String? selectedKondisiBan;
  String? selectedFuelConsumption;
  String? selectedOilQuality;
  String? selectedTingkatGetaran;
  String? selectedKecelakaan;

  final TextEditingController jenisServiceController = TextEditingController();
  final TextEditingController biayaController = TextEditingController();
  final TextEditingController tanggalServiceController =
      TextEditingController();
  final TextEditingController catatanController = TextEditingController();

  final List<String> kondisiKomponen = ["Baik", "Sedang", "Buruk"];
  final List<String> kecelakaan = ["Ya", "Tidak"];

  bool get isEdit => widget.docId != null;

  int kondisiToInt(String? kondisi) {
    switch (kondisi) {
      case 'Baik':
        return 100;
      case 'Sedang':
        return 50;
      case 'Buruk':
        return 0;
      default:
        return 0;
    }
  }

  String intToKondisi(dynamic nilai) {
    if (nilai == 100) return 'Baik';
    if (nilai == 50) return 'Sedang';
    if (nilai == 0) return 'Buruk';

    // Antisipasi kalau data lama masih bentuk String
    if (nilai == 'Baik') return 'Baik';
    if (nilai == 'Sedang') return 'Sedang';
    if (nilai == 'Buruk') return 'Buruk';

    return '';
  }

  Future<void> submitFunction(BuildContext context) async {
    if (selectedPlat == null ||
        selectedKondisiBan == null ||
        selectedKondisiBaterai == null ||
        selectedKondisiRem == null ||
        selectedFuelConsumption == null ||
        selectedOilQuality == null ||
        selectedTingkatGetaran == null ||
        jenisServiceController.text.isEmpty ||
        biayaController.text.isEmpty ||
        selectedTanggalService == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua field wajib diisi")));
      return;
    }

    try {
      final data = {
        'tanggal_perbaikan': Timestamp.fromDate(selectedTanggalService!),
        'jenis_kerusakan': jenisServiceController.text,
        'catatan_kerusakan': catatanController.text,
        'biaya_service': int.parse(biayaController.text.replaceAll('.', '')),
        'kecelakaan': selectedKecelakaan,

        // Data untuk ML / kondisi kendaraan
        'tire_preasure': kondisiToInt(selectedKondisiBan),
        'brake_condition': kondisiToInt(selectedKondisiRem),
        'battery_status': kondisiToInt(selectedKondisiBaterai),
        'fuel_consumption': kondisiToInt(selectedFuelConsumption),
        'oil_quality': kondisiToInt(selectedOilQuality),
        'vibration_level': kondisiToInt(selectedTingkatGetaran),
      };

      if (isEdit) {
        await FirebaseFirestore.instance
            .collection('kendaraan')
            .doc(widget.kendaraanId)
            .collection('service')
            .doc(widget.docId)
            .update(data);
      } else {
        await FirebaseFirestore.instance
            .collection('kendaraan')
            .doc(selectedPlat)
            .collection('service')
            .add({...data, 'created_at': FieldValue.serverTimestamp()});
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

  Stream<List<String>> getPlatKendaraan() {
    return FirebaseFirestore.instance.collection('kendaraan').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return doc['plat_kendaraan'] as String;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();

    if (isEdit && widget.data != null) {
      final data = widget.data!;

      selectedPlat = widget.kendaraanId;

      biayaController.text = data['biaya_service']?.toString() ?? '';
      jenisServiceController.text = data['jenis_kerusakan'] ?? '';
      catatanController.text = data['catatan_kerusakan'] ?? '';

      selectedKecelakaan = data['kecelakaan'];

      // Pakai field yang sekarang disimpan ke Firestore
      selectedKondisiBan = intToKondisi(data['tire_preasure']);
      selectedKondisiRem = intToKondisi(data['brake_condition']);
      selectedKondisiBaterai = intToKondisi(data['battery_status']);
      selectedFuelConsumption = intToKondisi(data['fuel_consumption']);
      selectedOilQuality = intToKondisi(data['oil_quality']);
      selectedTingkatGetaran = intToKondisi(data['vibration_level']);

      final tanggal = data['tanggal_perbaikan'];

      if (tanggal is Timestamp) {
        selectedTanggalService = tanggal.toDate();
        tanggalServiceController.text = DateFormat(
          'dd-MM-yyyy',
        ).format(selectedTanggalService!);
      } else if (tanggal is String) {
        tanggalServiceController.text = tanggal;
      }
    }
  }

  @override
  void dispose() {
    jenisServiceController.dispose();
    biayaController.dispose();
    tanggalServiceController.dispose();
    catatanController.dispose();
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DataServicePage()),
          ),
        ),
        title: Text(
          isEdit ? "Edit Data Service" : "Input Data Service",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  return const Text(
                    "Tidak ada data",
                    style: TextStyle(color: Colors.white),
                  );
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
                  dropdownColor: Colors.white,
                  decoration: _inputDecoration("Pilih Plat Kendaraan"),
                  style: const TextStyle(color: Colors.black),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  items: platList.map((plat) {
                    return DropdownMenuItem(
                      value: plat['id'],
                      child: Text(plat['plat'] ?? '-'),
                    );
                  }).toList(),
                  onChanged: isEdit
                      ? null
                      : (val) => setState(() => selectedPlat = val),
                );
              },
            ),

            const SizedBox(height: 16),

            const Text(
              "Tanggal Service",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              readOnly: true,
              controller: tanggalServiceController,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration("Pilih Tanggal"),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedTanggalService ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (pickedDate != null) {
                  setState(() {
                    selectedTanggalService = pickedDate;
                    tanggalServiceController.text = DateFormat(
                      'dd-MM-yyyy',
                    ).format(pickedDate);
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            const Text("Jenis Service", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: jenisServiceController,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration("Masukkan Jenis Service"),
            ),

            const SizedBox(height: 16),

            const Text(
              "Biaya Service (Rp)",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: biayaController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black),
              inputFormatters: [RupiahInputFormatter()],
              decoration: _inputDecoration("Masukkan Biaya Service").copyWith(
                prefixText: "Rp ",
                prefixStyle: const TextStyle(color: Colors.black),
              ),
            ),

            const SizedBox(height: 16),

            const Text("Kondisi Rem", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedKondisiRem,
              dropdownColor: Colors.white,
              decoration: _inputDecoration("Pilih Kondisi Rem"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: kondisiKomponen.map((kondisi) {
                return DropdownMenuItem(value: kondisi, child: Text(kondisi));
              }).toList(),
              onChanged: (val) => setState(() => selectedKondisiRem = val),
            ),

            const SizedBox(height: 8),

            const Text("Kondisi Ban", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedKondisiBan,
              dropdownColor: Colors.white,
              decoration: _inputDecoration("Pilih Kondisi Ban"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: kondisiKomponen.map((kondisi) {
                return DropdownMenuItem(value: kondisi, child: Text(kondisi));
              }).toList(),
              onChanged: (val) => setState(() => selectedKondisiBan = val),
            ),

            const SizedBox(height: 8),

            const Text(
              "Kondisi Baterai",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedKondisiBaterai,
              dropdownColor: Colors.white,
              decoration: _inputDecoration("Pilih Kondisi Baterai"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: kondisiKomponen.map((kondisi) {
                return DropdownMenuItem(value: kondisi, child: Text(kondisi));
              }).toList(),
              onChanged: (val) => setState(() => selectedKondisiBaterai = val),
            ),

            const SizedBox(height: 8),

            const Text(
              "Konsumsi Bahan Bakar",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedFuelConsumption,
              dropdownColor: Colors.white,
              decoration: _inputDecoration(
                "Pilih Kondisi Konsumsi Bahan Bakar",
              ),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: kondisiKomponen.map((kondisi) {
                return DropdownMenuItem(value: kondisi, child: Text(kondisi));
              }).toList(),
              onChanged: (val) => setState(() => selectedFuelConsumption = val),
            ),

            const SizedBox(height: 8),

            const Text("Kualitas Oli", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedOilQuality,
              dropdownColor: Colors.white,
              decoration: _inputDecoration("Pilih Kondisi Kualitas Oli"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: kondisiKomponen.map((kondisi) {
                return DropdownMenuItem(value: kondisi, child: Text(kondisi));
              }).toList(),
              onChanged: (val) => setState(() => selectedOilQuality = val),
            ),

            const SizedBox(height: 8),

            const Text(
              "Tingkat Getaran",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedTingkatGetaran,
              dropdownColor: Colors.white,
              decoration: _inputDecoration("Pilih Tingkat Getaran"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: kondisiKomponen.map((kondisi) {
                return DropdownMenuItem(value: kondisi, child: Text(kondisi));
              }).toList(),
              onChanged: (val) => setState(() => selectedTingkatGetaran = val),
            ),

            const SizedBox(height: 16),

            const Text("Kecelakaan", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedKecelakaan,
              dropdownColor: Colors.white,
              decoration: _inputDecoration("Pilih Status Kecelakaan"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: kecelakaan.map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (val) => setState(() => selectedKecelakaan = val),
            ),

            const SizedBox(height: 16),

            const Text(
              "Catatan Kerusakan",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: catatanController,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration("Masukkan Catatan Kerusakan"),
            ),

            const SizedBox(height: 30),

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
                  style: const TextStyle(
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
      ).copyWith(color: const Color(0xFF000000).withOpacity(0.5)),
      filled: true,
      fillColor: const Color(0xFFD9D9D9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
