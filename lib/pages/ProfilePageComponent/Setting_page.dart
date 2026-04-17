import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pertro_fleet/pages/fungsi/RupiahInputFormatter.dart';

class FormSettingProfile extends StatefulWidget {
  const FormSettingProfile({super.key});

  @override
  State<FormSettingProfile> createState() => _FormSettingProfileState();
}

class _FormSettingProfileState extends State<FormSettingProfile> {
  final TextEditingController hargaMinyakController = TextEditingController();
  final rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  int hargaMinyak = 0;
  Future<void> getHargaMinyak() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('5b6fQeBkcw3U78ynfAdU')
          .get();

      if (doc.exists) {
        setState(() {
          hargaMinyak = doc['harga_minyak'] ?? 0;
        });
      }
    } catch (e) {
      print("error ambil data: $e");
    }
  }

  Future<void> updateHargaMinyak() async {
    try {
      if (hargaMinyakController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inputan form tidak boleh kosong")),
        );
        return;
      }
      String cleanText = hargaMinyakController.text.replaceAll('.', '');
      int hargaBaru = int.parse(cleanText);

      await FirebaseFirestore.instance
          .collection('settings')
          .doc('5b6fQeBkcw3U78ynfAdU')
          .update({'harga_minyak': hargaBaru});

      await getHargaMinyak();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berhasil update harga minyak")),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    } catch (e) {
      print("Error update:$e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("gagal update")));
    }
  }

  @override
  void initState() {
    super.initState();
    getHargaMinyak();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B4996),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B4996),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Harga Minyak Sekarang",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              rupiahFormat.format(hargaMinyak),
              style: const TextStyle(color: Colors.white),
            ),
            SizedBox(height: 10),
            const Text(
              "Minyak Per Liter",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: hargaMinyakController,
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration("Masukkan Harga Minyak Per Liter")
                  .copyWith(
                    prefixText: "Rp ",
                    prefixStyle: const TextStyle(color: Colors.black),
                  ),
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
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Konfirmasi"),
                      content: const Text(
                        "Apakah yakin ingin mengupdate data?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // tutup dialog
                          },
                          child: const Text("Batal"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // tutup dialog dulu
                            updateHargaMinyak(); // baru update
                          },
                          child: const Text("Ya"),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  "Tambahkan Data",
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
