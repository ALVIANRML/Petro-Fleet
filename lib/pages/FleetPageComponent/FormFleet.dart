import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pertro_fleet/pages/fungsi/RupiahInputFormatter.dart';

class FormFleetPage extends StatefulWidget {
  const FormFleetPage({super.key});

  @override
  State<FormFleetPage> createState() => _FormFleetPageState();
}

class _FormFleetPageState extends State<FormFleetPage> {
  final TextEditingController platController = TextEditingController();
  final TextEditingController muatanController = TextEditingController();

  String? selectedModelKendaraan;
  String? selectedJenisBahanBakar;
  String? selectedUsiaKendaraan;
  String? selectedKapasitasMesin;
  String? selectedTahunProduksi;

  final List<String> modelKendaraan = [
    "Fuso 1050",
    "Mercedez-Benz 1040",
    "Hyundai 1890",
  ];

  final List<String> kapasitasMesin = ["220cc", "230", "420"];
  final List<String> tahunProduksi = ["2004", "2005", "2006"];
  final List<String> usiaKendaraan = ["Tidak Tau", "20", "30"];
  final List<String> jenisBahanBakar = ["Bensin", "Solar"];

  void showPesan(String pesan) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> tambahKendaraanFunction() async {
    if (platController.text.isEmpty) {
      showPesan("Plat Kendaraan belum diisi");
      return;
    }

    if (selectedModelKendaraan == null) {
      showPesan("Model kendaraan belum dipilih");
      return;
    }

    if (selectedUsiaKendaraan == null) {
      showPesan("Usia Kendaraan belum dipilih");
      return;
    }

    if (selectedTahunProduksi == null) {
      showPesan("Tahun Produksi belum dipilih");
      return;
    }

    if (selectedJenisBahanBakar == null) {
      showPesan("Jenis Bahan Bakar belum dipilih");
      return;
    }

    if (selectedKapasitasMesin == null) {
      showPesan("Kapasitas Mesin belum dipilih");
      return;
    }

    if (muatanController.text.isEmpty) {
      showPesan("Kapasitas Muatan belum diisi");
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('kendaraan').add({
        'plat_kendaraan': platController.text.trim(),
        'model_kendaraan': selectedModelKendaraan,
        'jenis_bahan_bakar': selectedJenisBahanBakar,
        'usia_kendaraan': selectedUsiaKendaraan,
        'kapasitas_mesin': selectedKapasitasMesin,
        'kapasitas_muatan': muatanController.text.trim(),
        'tahun_produksi': selectedTahunProduksi,
        'estimasi_masa_pakai': null,
        'odometer_kendaraan': 0,
        'total_jam_operasi': 0,
        'created_at': Timestamp.now(),
      });

      if (!mounted) return;

      showPesan("Data berhasil ditambahkan");

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      print("Error tambah kendaraan: $e");

      if (!mounted) return;

      showPesan("Gagal menambahkan data");
    }
  }

  @override
  void dispose() {
    platController.dispose();
    muatanController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
      filled: true,
      fillColor: const Color(0xFFD9D9D9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B4996),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B4996),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (!mounted) return;
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "Tambah Kendaraan",
          style: TextStyle(color: Colors.white),
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
            TextField(
              controller: platController,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration("Plat Kendaraan"),
            ),

            const SizedBox(height: 10),

            const Text(
              "Model Kendaraan",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedModelKendaraan,
              dropdownColor: Colors.white,
              decoration: _inputDecoration("Pilih Model Kendaraan"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: modelKendaraan.map((model) {
                return DropdownMenuItem(value: model, child: Text(model));
              }).toList(),
              onChanged: (val) {
                if (!mounted) return;
                setState(() {
                  selectedModelKendaraan = val;
                });
              },
            ),

            const SizedBox(height: 10),

            const Text("Usia Kendaraan", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedUsiaKendaraan,
              dropdownColor: Colors.white,
              decoration: _inputDecoration("Pilih Usia Kendaraan"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: usiaKendaraan.map((usia) {
                return DropdownMenuItem(value: usia, child: Text(usia));
              }).toList(),
              onChanged: (val) {
                if (!mounted) return;
                setState(() {
                  selectedUsiaKendaraan = val;
                });
              },
            ),

            const SizedBox(height: 10),

            const Text("Tahun Produksi", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedTahunProduksi,
              dropdownColor: Colors.white,
              decoration: _inputDecoration("Pilih Tahun Produksi"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: tahunProduksi.map((tahun) {
                return DropdownMenuItem(value: tahun, child: Text(tahun));
              }).toList(),
              onChanged: (val) {
                if (!mounted) return;
                setState(() {
                  selectedTahunProduksi = val;
                });
              },
            ),

            const SizedBox(height: 10),

            const Text(
              "Jenis Bahan Bakar",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedJenisBahanBakar,
              dropdownColor: Colors.white,
              decoration: _inputDecoration("Pilih Jenis Bahan Bakar"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: jenisBahanBakar.map((bahanBakar) {
                return DropdownMenuItem(
                  value: bahanBakar,
                  child: Text(bahanBakar),
                );
              }).toList(),
              onChanged: (val) {
                if (!mounted) return;
                setState(() {
                  selectedJenisBahanBakar = val;
                });
              },
            ),

            const SizedBox(height: 10),

            const Text(
              "Kapasitas Mesin",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedKapasitasMesin,
              dropdownColor: Colors.white,
              decoration: _inputDecoration("Pilih Kapasitas Mesin"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: kapasitasMesin.map((mesin) {
                return DropdownMenuItem(value: mesin, child: Text(mesin));
              }).toList(),
              onChanged: (val) {
                if (!mounted) return;
                setState(() {
                  selectedKapasitasMesin = val;
                });
              },
            ),

            const SizedBox(height: 10),

            const Text(
              "Kapasitas Muatan",
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
                "Kapasitas Muatan",
              ).copyWith(suffixText: "kg"),
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
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text("Konfirmasi"),
                      content: const Text(
                        "Apakah anda yakin ingin menambahkan data?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                          },
                          child: const Text("Batal"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          child: const Text("Ya"),
                        ),
                      ],
                    ),
                  );

                  if (!mounted) return;

                  if (confirm == true) {
                    await tambahKendaraanFunction();
                  }
                },
                child: const Text(
                  "Tambahkan Kendaraan",
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
}
