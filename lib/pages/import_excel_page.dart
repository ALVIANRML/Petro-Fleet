import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ImportExcelPage extends StatefulWidget {
  const ImportExcelPage({super.key});

  @override
  State<ImportExcelPage> createState() => _ImportExcelPageState();
}

class _ImportExcelPageState extends State<ImportExcelPage> {
  bool isLoading = false;
  String hasilImport = "";

  // GANTI DENGAN ID KENDARAAN DI FIREBASE
  final String kendaraanId = "BPsD35i9Jy1PlaIiRYBc";

  // GANTI DENGAN ID SOPIR / PENGEMUDI DI FIREBASE
  final String idPengemudi = "rMgyV4UXZdPMsO6sRCNQnVw0bFg1";

  // Karena kamu ingin hasilnya seperti screenshot:
  // berat_kg = jumlah_muatan
  // Kalau nanti mau benar-benar konversi pelumas, ubah jadi liter * 0.88
  double hitungBeratKg(num totalLiter) {
    return totalLiter.toDouble();

    // Kalau mau konversi pelumas yang lebih realistis:
    // return totalLiter * 0.88;
  }

  num parseAngka(dynamic value) {
    if (value == null) return 0;

    String text = value.toString().trim();

    if (text.isEmpty) return 0;

    text = text.replaceAll('.', '').replaceAll(',', '.');

    return num.tryParse(text) ?? 0;
  }

  String getCellValue(List<Data?> row, int index) {
    if (index >= row.length) return "";
    return row[index]?.value?.toString().trim() ?? "";
  }

  DateTime? parseTanggal(String value) {
    if (value.trim().isEmpty) return null;

    try {
      return DateFormat("dd/MM/yyyy").parse(value);
    } catch (_) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> importExcelKeFirebase() async {
    try {
      setState(() {
        isLoading = true;
        hasilImport = "";
      });

      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null) {
        setState(() {
          isLoading = false;
          hasilImport = "Import dibatalkan";
        });
        return;
      }

      final Uint8List? bytes = result.files.single.bytes;

      if (bytes == null) {
        setState(() {
          isLoading = false;
          hasilImport = "File Excel tidak terbaca";
        });
        return;
      }

      final excel = Excel.decodeBytes(bytes);

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null) {
        setState(() {
          isLoading = false;
          hasilImport = "Sheet Excel tidak ditemukan";
        });
        return;
      }

      final rows = sheet.rows;

      if (rows.length <= 1) {
        setState(() {
          isLoading = false;
          hasilImport = "Excel kosong";
        });
        return;
      }

      final Map<String, Map<String, dynamic>> groupData = {};

      // index 0 = header
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        final group = getCellValue(row, 0); // Kolom A
        final tanggalText = getCellValue(row, 1); // Kolom B
        final jenisMuatan = getCellValue(row, 2); // Kolom C
        final qty = parseAngka(getCellValue(row, 3)); // Kolom D
        final liter = parseAngka(getCellValue(row, 4)); // Kolom E
        final tujuanMuatan = getCellValue(row, 6); // Kolom G
        final lokasiAwal = getCellValue(row, 7); // Kolom H
        final jarak = parseAngka(getCellValue(row, 8)); // Kolom I
        final jam = parseAngka(getCellValue(row, 9)); // Kolom J

        if (group.isEmpty && tanggalText.isEmpty && jenisMuatan.isEmpty) {
          continue;
        }

        if (group.isEmpty) {
          continue;
        }

        final key = group;

        final totalLiter = qty * liter;
        final beratKg = hitungBeratKg(totalLiter);

        if (!groupData.containsKey(key)) {
          groupData[key] = {
            'tanggal_text': tanggalText,
            'lokasi_awal': lokasiAwal,
            'tujuan_muatan': tujuanMuatan,
            'jarak_km': jarak,
            'usage_hours': jam,
            'muatan': <Map<String, dynamic>>[],
          };
        }

        groupData[key]!['muatan'].add({
          'berat_kg': beratKg,
          'jenis_muatan': jenisMuatan.toUpperCase(),
          'jumlah_muatan': totalLiter,
          'satuan_awal': 'liter',
        });
      }

      int berhasil = 0;

      for (final item in groupData.values) {
        final List<Map<String, dynamic>> muatan =
            List<Map<String, dynamic>>.from(item['muatan']);

        final totalJumlahMuatan = muatan.fold<num>(
          0,
          (total, m) => total + (m['jumlah_muatan'] as num),
        );

        final totalBeratKg = muatan.fold<num>(
          0,
          (total, m) => total + (m['berat_kg'] as num),
        );

        final tanggalDate = parseTanggal(item['tanggal_text']);

        final docRef = await FirebaseFirestore.instance
            .collection('kendaraan')
            .doc(kendaraanId)
            .collection('perjalanan')
            .add({
              'approved_arrival': true,
              'approved_by_driver': true,
              'created_at': FieldValue.serverTimestamp(),
              'id_pengemudi': idPengemudi,
              'lokasi_awal': item['lokasi_awal'],

              'muatan': muatan,

              'status': 'completed',
              'tanggal': tanggalDate != null
                  ? Timestamp.fromDate(tanggalDate)
                  : FieldValue.serverTimestamp(),
              'tanggal_tiba': tanggalDate != null
                  ? Timestamp.fromDate(tanggalDate)
                  : FieldValue.serverTimestamp(),

              'total_berat_kg': totalBeratKg,
              'total_jumlah_muatan': totalJumlahMuatan,
              'total_muatan_diterima': 0,
              'jarak_km': item['jarak_km'],
              'usage_hours': item['usage_hours'],
              'tujuan_muatan': item['tujuan_muatan'],
              'uang_bensin': 100000,
              'upah_driver': 100000,
            });

        print("ID perjalanan dari Firebase: ${docRef.id}");

        berhasil++;
      }

      setState(() {
        isLoading = false;
        hasilImport = "Berhasil import $berhasil perjalanan";
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasilImport = "Gagal import: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B4996),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B4996),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Import Excel",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Import Data Perjalanan dari Excel",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : importExcelKeFirebase,
                icon: const Icon(Icons.upload_file),
                label: Text(isLoading ? "Mengimport..." : "Pilih File Excel"),
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading) const CircularProgressIndicator(color: Colors.white),

            if (hasilImport.isNotEmpty)
              Text(
                hasilImport,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
