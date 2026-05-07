import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FormAddProfile extends StatefulWidget {
  const FormAddProfile({super.key});

  @override
  State<FormAddProfile> createState() => _FormAddProfileState();
}

class _FormAddProfileState extends State<FormAddProfile> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool isPasswordHidden = true;
  final TextEditingController passwordController = TextEditingController();
  String? selectedPosisi;

  final List<String> posisiList = ["Admin", "Sopir"];

  Future<void> registerFunction(BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );

      String uid = userCredential.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'id_user_authentication': uid,
        'nama': namaController.text,
        'email': emailController.text,
        'posisi': selectedPosisi,
        'created_at': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Berhasil daftar & simpan data"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    } on FirebaseAuthException catch (e) {
      String message = "Terjadi Kesalahan";

      if (e.code == 'email-already-in-use') {
        message = 'email sudah digunakan';
      } else if (e.code == 'weak-password') {
        message = 'Password terlalu lemah';
      } else if (e.code == 'invalid-email') {
        message = "format email tidak valid";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
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
          "Tambah Data Pengguna",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nama Pengguna", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: namaController,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration("Nama Pengguna"),
            ),
            SizedBox(height: 10),
            const Text("Email", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration("Email"),
            ),
            SizedBox(height: 10),
            const Text("Password", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              obscureText: isPasswordHidden,
              controller: passwordController,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration("Password").copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordHidden = !isPasswordHidden;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            const Text("Jabatan", style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedPosisi,
              dropdownColor: const Color(0xFFFFFFFF),
              decoration: _inputDecoration("Pilih Jabatan Anda"),
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
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
                    registerFunction(context); // ✅ pakai context halaman (aman)
                  }
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
