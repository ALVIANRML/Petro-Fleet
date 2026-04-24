import 'package:flutter/material.dart';

class ApprovalPerjalananPage extends StatefulWidget {
  const ApprovalPerjalananPage({super.key});
  @override
  State<ApprovalPerjalananPage> createState() => _ApprovalPerjalananPageState();
}

class _ApprovalPerjalananPageState extends State<ApprovalPerjalananPage> {
  final TextEditingController muatanDiterimaController =
      TextEditingController();
  final TextEditingController ddController = TextEditingController();
  final TextEditingController mmController = TextEditingController();
  final TextEditingController yyyyController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0B4996),
      appBar: AppBar(
        backgroundColor: Color(0xFF0B4996),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Approval Perjalanan',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plat Kendaraan:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('BK 1546 TRE', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            Text(
              'Tanggal Berangkat:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('13 Maret 2026', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            Text(
              'Lokasi Awal:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Pertamina Medan', style: TextStyle(color: Colors.white)),
            Padding(
              padding: const EdgeInsets.only(left: 30), // geser ke kanan
              child: Icon(Icons.arrow_downward, color: Colors.white),
            ),
            Text(
              'Lokasi Akhir:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Pertamina Aceh', style: TextStyle(color: Colors.white)),
            SizedBox(height: 10),
            Text(
              'Upah Perjalanan:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Rp 2.000.000', style: TextStyle(color: Colors.white)),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Muatan (Rp):',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rp 2.000.000',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Muatan (L):',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('2 L', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jumlah Muatan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),

                TextField(
                  controller: muatanDiterimaController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    "Masukkan Jumlah Muatan Yang Diterima",
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),
            const Text(
              "Tanggal Service",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ddController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("DD"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: mmController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("MM"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: yyyyController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("YYYY"),
                  ),
                ),
              ],
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
