import 'package:flutter/material.dart';
import 'package:pertro_fleet/pages/ActivityPageComponent/activity_data_service.dart';

class FormDataService extends StatefulWidget {
  const FormDataService({super.key});

  @override
  State<FormDataService> createState() => _FormDataServiceState();
}

class _FormDataServiceState extends State<FormDataService> {
  String? selectedPlat;
  final TextEditingController jenisServiceController = TextEditingController();
  final TextEditingController biayaController = TextEditingController();
  final TextEditingController odometerController = TextEditingController();
  final TextEditingController ddController = TextEditingController();
  final TextEditingController mmController = TextEditingController();
  final TextEditingController yyyyController = TextEditingController();

  final List<String> platList = ["BK 1542 TRE", "BK 2000 ABC", "BK 3321 XYZ"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1A1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1A1D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DataServicePage()),
          ),
        ),
        title: const Text(
          "Input Data Service",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plat Kendaraan
            const Text("Plat Kendaraan", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedPlat,
              dropdownColor: const Color(0xFF2C2C2C),
              decoration: _inputDecoration("Pilih Plat Kendaraan"),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: platList.map((plat) {
                return DropdownMenuItem(value: plat, child: Text(plat));
              }).toList(),
              onChanged: (val) => setState(() => selectedPlat = val),
            ),
            const SizedBox(height: 16),

            // Jenis Service
            const Text("Jenis Service", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: jenisServiceController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Masukkan Jenis Service"),
            ),
            const SizedBox(height: 16),

            // Biaya Service
            const Text(
              "Biaya Service (Rp)",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: biayaController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Masukkan Biaya Service (Rp)"),
            ),
            const SizedBox(height: 16),

            // Odometer
            const Text(
              "Odometer saat Servis",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: odometerController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Masukkan Odometer saat Servis"),
            ),
            const SizedBox(height: 16),

            // Tanggal Service
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
