import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pertro_fleet/pages/fungsi/RupiahInputFormatter.dart';
import 'package:pertro_fleet/pages/ActivityPageComponent/form_data_perjalanan.dart';

const String kStatusInTransit = 'in_transit';
const String kStatusOnTrip = 'on_trip';
const String kStatusCompleted = 'completed';

class DetailPerjalananPage extends StatefulWidget {
  final String currentStatus;
  final String docId;
  final String kendaraanId;
  final Map<String, dynamic> data;

  const DetailPerjalananPage({
    super.key,
    required this.currentStatus,
    required this.docId,
    required this.kendaraanId,
    required this.data,
  });

  @override
  State<DetailPerjalananPage> createState() => _DetailPerjalananPageState();
}

class _DetailPerjalananPageState extends State<DetailPerjalananPage> {
  final TextEditingController muatanDiterimaController =
      TextEditingController();
  final TextEditingController tanggalTibaController = TextEditingController();

  String? _userRole;
  bool _loadingRole = true;
  bool _isLoadingApprove = false;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      setState(() => _loadingRole = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    setState(() {
      _userRole = doc.data()?['posisi'] as String?;
      _loadingRole = false;
    });
  }

  String formatRupiah(dynamic value) {
    final num = int.tryParse(value.toString()) ?? 0;

    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String formatTanggal(dynamic value) {
    if (value == null) return '-';

    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}-${date.month}-${date.year}';
    }

    return value.toString();
  }

  String formatJam(dynamic value) {
    if (value == null) return '-';

    if (value is Timestamp) {
      final date = value.toDate();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day-$month-$year $hour:$minute';
    }

    return value.toString();
  }

  DocumentReference get docRef => FirebaseFirestore.instance
      .collection('kendaraan')
      .doc(widget.kendaraanId)
      .collection('perjalanan')
      .doc(widget.docId);

  Future<Position?> _getLocationWithValidation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.location_off, color: Colors.red),
                SizedBox(width: 8),
                Text('GPS Tidak Aktif'),
              ],
            ),
            content: const Text(
              'Lokasi HP kamu harus dihidupkan terlebih dahulu sebelum konfirmasi keberangkatan.\n\nHidupkan GPS, lalu coba lagi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3A8BF0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await Geolocator.openLocationSettings();
                },
                child: const Text(
                  'Buka Pengaturan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }

      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin lokasi ditolak. Tidak bisa konfirmasi keberangkatan.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }

        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.location_disabled, color: Colors.red),
                SizedBox(width: 8),
                Text('Izin Lokasi Diblokir'),
              ],
            ),
            content: const Text(
              'Izin lokasi diblokir permanen. Buka pengaturan aplikasi untuk mengaktifkannya.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A8BF0),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await Geolocator.openAppSettings();
                },
                child: const Text(
                  'Buka Pengaturan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }

      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendapatkan lokasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return null;
    }
  }

  Future<void> _approveStartTrip(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Keberangkatan'),
        content: const Text(
          'Apakah kamu sudah siap berangkat?\nLokasi GPS kamu akan direkam.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A8BF0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Ya, Berangkat!',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoadingApprove = true);

    final position = await _getLocationWithValidation();

    setState(() => _isLoadingApprove = false);

    if (position == null) return;

    final Timestamp driverApprovedAt = Timestamp.now();

    await docRef.update({
      'status': kStatusOnTrip,
      'approved_by_driver': true,

      // Waktu sopir approve / mulai perjalanan
      'driver_approved_at': driverApprovedAt,
      'waktu_berangkat': driverApprovedAt,

      'lokasi_berangkat': GeoPoint(position.latitude, position.longitude),
      'accuracy': position.accuracy,
    });

    if (context.mounted) Navigator.pop(context, true);
  }

  Future<void> _approveCompleted(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Tandai perjalanan ini sebagai Completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (muatanDiterimaController.text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Muatan diterima belum diisi")),
        );
      }
      return;
    }

    if (tanggalTibaController.text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tanggal tiba belum diisi")),
        );
      }
      return;
    }

    final kendaraanDoc = await FirebaseFirestore.instance
        .collection('kendaraan')
        .doc(widget.kendaraanId)
        .get();

    final lastLat = kendaraanDoc.data()?['last_lat'];
    final lastLng = kendaraanDoc.data()?['last_lng'];

    final perjalananSnapshot = await docRef.get();
    final perjalananData = perjalananSnapshot.data() as Map<String, dynamic>?;

    final driverApprovedAt = perjalananData?['driver_approved_at'];

    final Timestamp adminCompletedAt = Timestamp.now();

    double usageHours = 0;

    if (driverApprovedAt is Timestamp) {
      final startTime = driverApprovedAt.toDate();
      final endTime = adminCompletedAt.toDate();

      final duration = endTime.difference(startTime);

      usageHours = double.parse((duration.inMinutes / 60).toStringAsFixed(2));
    }

    await docRef.update({
      'status': kStatusCompleted,
      'approved_arrival': true,

      'total_muatan_diterima': int.parse(
        muatanDiterimaController.text.replaceAll('.', ''),
      ),

      'tanggal_tiba': tanggalTibaController.text,

      // Waktu admin complete / selesai perjalanan
      'admin_completed_at': adminCompletedAt,
      'waktu_selesai': adminCompletedAt,

      // Lama penggunaan kendaraan dalam jam
      'usage_hours': usageHours,

      'lokasi_akhir': lastLat != null && lastLng != null
          ? {'latitude': lastLat, 'longitude': lastLng}
          : null,
    });

    if (context.mounted) Navigator.pop(context, true);
  }

  Future<void> hapusData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Yakin ingin menghapus data perjalanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await docRef.delete();

      if (context.mounted) Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    tanggalTibaController.dispose();
    muatanDiterimaController.dispose();
    super.dispose();
  }

  Color get _badgeColor {
    switch (widget.currentStatus) {
      case kStatusOnTrip:
        return const Color(0xFF3A8BF0);
      case kStatusCompleted:
        return const Color(0xFF00DB21);
      default:
        return Colors.orange;
    }
  }

  String get _badgeLabel {
    switch (widget.currentStatus) {
      case kStatusOnTrip:
        return 'On Trip';
      case kStatusCompleted:
        return 'Completed';
      default:
        return 'In Transit';
    }
  }

  @override
  Widget build(BuildContext context) {
    final platKendaraan = widget.data['plat_kendaraan'] ?? '-';
    final tanggal = widget.data['tanggal'] ?? '-';
    final tanggalTiba = widget.data['tanggal_tiba'] ?? '-';
    final lokasi = widget.data['lokasi_awal'] ?? '-';
    final tujuan = widget.data['tujuan_muatan'] ?? '-';
    final upahDriver = widget.data['upah_driver'] ?? 0;
    final uangBensin = widget.data['uang_bensin'] ?? 0;
    final List muatanList = widget.data['muatan'] ?? [];
    final totalJumlahMuatan = widget.data['total_jumlah_muatan'] ?? 0;
    final jumlahMuatanDiterima = widget.data['total_muatan_diterima'] ?? 0;
    final usageHours = widget.data['usage_hours'];
    final driverApprovedAt = widget.data['driver_approved_at'];
    final adminCompletedAt = widget.data['admin_completed_at'];

    final isCompleted = widget.currentStatus == kStatusCompleted;
    final isOnTrip = widget.currentStatus == kStatusOnTrip;
    final isInTransit = widget.currentStatus == kStatusInTransit;

    return Scaffold(
      backgroundColor: const Color(0xFF0B4996),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B4996),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Detail Perjalanan',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _loadingRole
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _badgeColor,
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Text(
                        _badgeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _label('Nama Pengemudi:'),
                  _buildPengemudi(),
                  const SizedBox(height: 10),

                  _label('Plat Kendaraan:'),
                  _value(platKendaraan),
                  const SizedBox(height: 10),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Tanggal Berangkat:'),
                            _value(formatTanggal(tanggal)),
                          ],
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Tanggal Tiba:'),
                              _value(formatTanggal(tanggalTiba)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (driverApprovedAt != null) ...[
                    const SizedBox(height: 10),
                    _label('Waktu Sopir Approve:'),
                    _value(formatJam(driverApprovedAt)),
                  ],

                  if (adminCompletedAt != null) ...[
                    const SizedBox(height: 10),
                    _label('Waktu Admin Complete:'),
                    _value(formatJam(adminCompletedAt)),
                  ],

                  if (isCompleted && usageHours != null) ...[
                    const SizedBox(height: 10),
                    _label('Usage Hours:'),
                    _value('$usageHours jam'),
                  ],

                  const SizedBox(height: 10),

                  _label('Lokasi Awal:'),
                  _value(lokasi),
                  const Padding(
                    padding: EdgeInsets.only(left: 30),
                    child: Icon(Icons.arrow_downward, color: Colors.white),
                  ),
                  _label('Lokasi Akhir:'),
                  _value(tujuan),
                  const SizedBox(height: 10),

                  _label('Upah Driver:'),
                  _value('Rp ${formatRupiah(upahDriver)}'),
                  const SizedBox(height: 10),

                  _label('Uang Bensin:'),
                  _value('Rp ${formatRupiah(uangBensin)}'),
                  const SizedBox(height: 10),

                  _label('Data Muatan:'),
                  const SizedBox(height: 6),

                  if (muatanList.isEmpty)
                    _value('-')
                  else
                    Column(
                      children: muatanList.map((item) {
                        final jenisMuatan = item['jenis_muatan'] ?? '-';
                        final jumlahMuatan = item['jumlah_muatan'] ?? 0;

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  jenisMuatan.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                "${formatRupiah(jumlahMuatan)} Kg",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 8),

                  _label('Total Muatan (L):'),
                  _value("${formatRupiah(totalJumlahMuatan)} L"),

                  if (isCompleted) ...[
                    const SizedBox(height: 10),
                    _label('Muatan Diterima (L):'),
                    _value("${formatRupiah(jumlahMuatanDiterima)} L"),
                  ],

                  const SizedBox(height: 24),

                  if (isInTransit) ...[
                    if (_userRole == 'Admin') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A8BF0),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FormDataPerjalanan(
                                  docId: widget.docId,
                                  kendaraanId: widget.kendaraanId,
                                  data: widget.data,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Edit Data',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF0000),
                          ),
                          onPressed: () => hapusData(context),
                          child: const Text(
                            'Hapus Data',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (_userRole == 'Sopir') ...[
                      _infoBox(
                        icon: Icons.info_outline,
                        message:
                            'Tekan tombol di bawah untuk konfirmasi bahwa kamu sudah berangkat. Lokasi GPS kamu akan direkam.',
                      ),

                      const SizedBox(height: 12),

                      if (_isLoadingApprove)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A8BF0).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Mengambil lokasi GPS...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3A8BF0),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.local_shipping,
                              color: Colors.white,
                            ),
                            onPressed: () => _approveStartTrip(context),
                            label: const Text(
                              'Konfirmasi Berangkat',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],

                  if (isOnTrip) ...[
                    if (_userRole == 'Admin') ...[
                      _label('Muatan Diterima'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: muatanDiterimaController,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          RupiahInputFormatter(),
                        ],
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration(
                          "Masukkan Jumlah Muatan",
                        ).copyWith(suffixText: "L"),
                      ),

                      const SizedBox(height: 16),

                      _label('Tanggal Tiba'),
                      const SizedBox(height: 6),
                      TextField(
                        readOnly: true,
                        controller: tanggalTibaController,
                        decoration: _inputDecoration("Pilih Tanggal"),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );

                          if (pickedDate != null) {
                            setState(() {
                              final day = pickedDate.day.toString().padLeft(
                                2,
                                '0',
                              );
                              final month = pickedDate.month.toString().padLeft(
                                2,
                                '0',
                              );
                              final year = pickedDate.year.toString();

                              tanggalTibaController.text = '$day-$month-$year';
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00DB21),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: () => _approveCompleted(context),
                          child: const Text(
                            '✓ Tandai Completed',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (_userRole == 'Sopir') ...[
                      _infoBox(
                        icon: Icons.local_shipping,
                        message:
                            'Perjalanan sedang berlangsung. Hubungi admin jika ada kendala.',
                      ),
                    ],
                  ],

                  if (isCompleted) ...[
                    _infoBox(
                      icon: Icons.check_circle_outline,
                      message: 'Perjalanan ini sudah selesai.',
                      color: const Color(0xFF00DB21),
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String message,
    Color color = const Color(0xFF3A8BF0),
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPengemudi() {
    final pengemudiId = widget.data['id_pengemudi'];

    if (pengemudiId == null) return _value("-");

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(pengemudiId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            "Loading...",
            style: TextStyle(color: Colors.white),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _value("User tidak ditemukan");
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return _value(data['nama'] ?? '-');
      },
    );
  }

  Widget _value(String text) {
    return Text(text, style: const TextStyle(color: Colors.white));
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
}
