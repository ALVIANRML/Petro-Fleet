import 'package:flutter/material.dart';

class FormEditProfile extends StatefulWidget {
  const FormEditProfile({super.key});

  @override
  State<FormEditProfile> createState() => _ForEditProfileState();
}

class _ForEditProfileState extends State<FormEditProfile> {
  final TextEditingController namaController = TextEditingController();
  String? selectedPosisi;

  final List<String> posisiList = ["ketua", "abangda", "adinda"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1A1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1A1D),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nama Pengguna",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: namaController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Masukkan Nama Anda"),
            ),
            const SizedBox(height: 30),
            const Text("Jabatan", style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedPosisi,
              dropdownColor: const Color(0xFF2C2C2C),
              decoration: _inputDecoration("Pilih Jabatan Anda"),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: posisiList.map((posisi) {
                return DropdownMenuItem(value: posisi, child: Text(posisi));
              }).toList(),
              onChanged: (val) => setState(() => selectedPosisi = val),
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
                  // logika simpan data
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
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
