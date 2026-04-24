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

  Future<void> tambahKendaraanFunction(BuildContext context) async {
    if (platController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Plat Kendaraan belum diisi")));
    }
    if (selectedJenisBahanBakar == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Model kendaraan belum dipilih")));
    }
    if (selectedUsiaKendaraan == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Usia Kendaraan belum dipilih")));
    }
    if (selectedTahunProduksi == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Tahun Produksi belum dipilih")));
    }
    if (selectedJenisBahanBakar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Jenis Bahan Bakar belum dipilih")),
      );
    }
    if (selectedKapasitasMesin == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Kapasitas Mesin belum dipilih")));
    }
    if (muatanController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Kapasitas Muatan belum diisi")));
    }
    try {
      await FirebaseFirestore.instance.collection('kendaraan').add({
        'plat_kendaraan': platController.text,
        'model_kendaraan': selectedModelKendaraan,
        'jenis_bahan_bakar': selectedJenisBahanBakar,
        'usia_kendaraan': selectedUsiaKendaraan,
        'kapasitas_mesin': selectedKapasitasMesin,
        'kapasitas_muatan': muatanController.text,
        'tahun_produksi': selectedTahunProduksi,
        'estimasi_masa_pakai': null,
        'odometer_kendaraan': 0,
        'total_jam_operasi': 0,
        'created_at': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data berhasil ditambahkan")),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    } catch (e) {
      {
        print("Error $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal menambahkan data")));
      }
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
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // plat kendaraan
            const Text("Plat Kendaraan", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: platController,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration("Plat Kendaraan"),
            ),
            SizedBox(height: 10),

            // Model kendaraan
            const Text(
              "Model Kendaraan",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedModelKendaraan,
              dropdownColor: const Color(0xFFFFFFFF),
              decoration: _inputDecoration("Pilih Model Kendaraan"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: modelKendaraan.map((posisi) {
                return DropdownMenuItem(value: posisi, child: Text(posisi));
              }).toList(),
              onChanged: (val) => setState(() => selectedModelKendaraan = val),
            ),

            SizedBox(height: 10),
            const Text(
              "Usia Kendaraan",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedUsiaKendaraan,
              dropdownColor: const Color(0xFFFFFFFF),
              decoration: _inputDecoration("Pilih Usia Kendaraan"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: usiaKendaraan.map((usia) {
                return DropdownMenuItem(value: usia, child: Text(usia));
              }).toList(),
              onChanged: (val) => setState(() => selectedUsiaKendaraan = val),
            ),
            SizedBox(height: 10),
            const Text(
              "Tahun Produksi",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedTahunProduksi,
              dropdownColor: const Color(0xFFFFFFFF),
              decoration: _inputDecoration("Pilih Model Kendaraan"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: tahunProduksi.map((tahun) {
                return DropdownMenuItem(value: tahun, child: Text(tahun));
              }).toList(),
              onChanged: (val) => setState(() => selectedTahunProduksi = val),
            ),
            SizedBox(height: 10),
            const Text(
              "Jenis Bahan Bakar",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedJenisBahanBakar,
              dropdownColor: const Color(0xFFFFFFFF),
              decoration: _inputDecoration("Pilih Model Kendaraan"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: jenisBahanBakar.map((bahanBakar) {
                return DropdownMenuItem(
                  value: bahanBakar,
                  child: Text(bahanBakar),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedJenisBahanBakar = val),
            ),
            SizedBox(height: 10),

            const Text(
              "Kapasitas Mesin",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedKapasitasMesin,
              dropdownColor: const Color(0xFFFFFFFF),
              decoration: _inputDecoration("Pilih Kapasitas Mesin"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: kapasitasMesin.map((mesin) {
                return DropdownMenuItem(value: mesin, child: Text(mesin));
              }).toList(),
              onChanged: (val) => setState(() => selectedKapasitasMesin = val),
            ),
            SizedBox(height: 10),
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
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration(
                "Kapasitas Muatan",
              ).copyWith(suffixText: "kg"),
            ),

            SizedBox(height: 30),
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
                      content: const Text(
                        "Apakah anda yakin ingin menambahkan data?",
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
                    tambahKendaraanFunction(
                      context,
                    ); // ✅ pakai context halaman (aman)
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
