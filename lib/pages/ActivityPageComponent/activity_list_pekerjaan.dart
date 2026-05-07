import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pertro_fleet/pages/ActivityPageComponent/activity_detail_perjalanan.dart';
import 'package:pertro_fleet/pages/main_dashboard_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class ListPekerjaanPage extends StatefulWidget {
  final String initialTab;

  const ListPekerjaanPage({super.key, this.initialTab = 'in_transit'});

  @override
  ListPekerjaanPageState createState() => ListPekerjaanPageState();
}

class ListPekerjaanPageState extends State<ListPekerjaanPage> {
  final user = FirebaseAuth.instance.currentUser;
  String get uid => user!.uid;
  DateTime? selectedDate;
  String searchQuery = '';

  late String activeTab;

  @override
  void initState() {
    super.initState();
    activeTab = widget.initialTab;
  }

  // ─── CEK & MINTA IZIN LOKASI ────────────────────────────────────────────────
  /// Mengembalikan true jika lokasi sudah siap digunakan.
  /// Jika GPS mati atau permission ditolak, tampilkan dialog dan kembalikan false.
  Future<bool> _ensureLocationReady(BuildContext context) async {
    // 1. Periksa apakah layanan GPS aktif
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return false;
      final shouldOpen = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('GPS Tidak Aktif'),
          content: const Text(
            'Untuk melakukan perjalanan, GPS pada perangkat Anda harus diaktifkan terlebih dahulu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      );

      if (shouldOpen == true) {
        await Geolocator.openLocationSettings();
        // Beri waktu user mengaktifkan GPS lalu periksa lagi
        await Future.delayed(const Duration(seconds: 2));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return false;
      } else {
        return false;
      }
    }

    // 2. Periksa permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi ditolak. Perjalanan tidak bisa dimulai.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return false;
      final shouldOpenApp = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Izin Lokasi Diblokir'),
          content: const Text(
            'Izin lokasi telah diblokir secara permanen. Buka pengaturan aplikasi untuk mengaktifkannya.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      );
      if (shouldOpenApp == true) {
        await Geolocator.openAppSettings();
      }
      return false;
    }

    return true; // Semua OK
  }

  // ─── AMBIL DATA PERJALANAN ───────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getPerjalananData(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('perjalanan')
        .where('status', isEqualTo: activeTab)
        .where('id_pengemudi', isEqualTo: userId)
        .get();

    final List<Map<String, dynamic>> result = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final kendaraanRef = doc.reference.parent.parent;

      String platKendaraan = '-';

      if (kendaraanRef != null) {
        final kendaraanDoc = await kendaraanRef.get();
        platKendaraan = kendaraanDoc.data()?['plat_kendaraan'] ?? '-';
      }

      result.add({
        'id': doc.id,
        'kendaraan_id': kendaraanRef?.id,
        'plat_kendaraan': platKendaraan,
        ...data,
      });
    }

    return result;
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Widget _buildTabButton(String label, String tabKey) {
    final isActive = activeTab == tabKey;

    Color activeColor;
    if (tabKey == 'in_transit') {
      activeColor = const Color(0xFFD97706);
    } else if (tabKey == 'on_trip') {
      activeColor = const Color(0xFF2563EB);
    } else {
      activeColor = const Color(0xFF16A34A);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            activeTab = tabKey;
            selectedDate = null;
            searchQuery = '';
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeColor : const Color(0xFF0A3A7A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showOnlyTwoTabs =
        activeTab == 'on_trip' || activeTab == 'in_transit';

    return Scaffold(
      backgroundColor: const Color(0xFF0B4996),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardPage(initialIndex: 2),
              ),
            );
          },
        ),
        title: const Text(
          "List Pekerjaan",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B4996),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── TAB BAR ──────────────────────────────────────────────
            Row(
              children: [
                _buildTabButton("In Transit", "in_transit"),
                const SizedBox(width: 8),
                _buildTabButton("On Trip", "on_trip"),
                if (!showOnlyTwoTabs) ...[
                  const SizedBox(width: 8),
                  _buildTabButton("Completed", "completed"),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── SEARCH ───────────────────────────────────────────────
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Cari...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 10),

            // ── DATE PICKER ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => pickDate(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A59BA),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate == null
                          ? "Pilih Tanggal"
                          : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (selectedDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDate = null;
                          });
                        },
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── HEADER TABEL ──────────────────────────────────────────
            Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    "Plat Kendaraan",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Tanggal",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Tujuan",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Aksi",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white),

            // ── LIST DATA ─────────────────────────────────────────────
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                key: ValueKey(activeTab),
                future: getPerjalananData(user!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Terjadi Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "Tidak Ada Data",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final docs =
                      snapshot.data!.where((data) {
                        final plat = (data['plat_kendaraan'] ?? '')
                            .toString()
                            .toLowerCase();
                        final matchSearch =
                            searchQuery.isEmpty || plat.contains(searchQuery);

                        final matchDate =
                            selectedDate == null ||
                            (() {
                              final tglRaw = data['tanggal'];
                              if (tglRaw is Timestamp) {
                                final d = tglRaw.toDate();
                                return d.day == selectedDate!.day &&
                                    d.month == selectedDate!.month &&
                                    d.year == selectedDate!.year;
                              }
                              if (tglRaw is String) {
                                try {
                                  final parts = tglRaw.split('-');
                                  if (parts.length == 3) {
                                    final d = DateTime(
                                      int.parse(parts[2]),
                                      int.parse(parts[1]),
                                      int.parse(parts[0]),
                                    );
                                    return d.day == selectedDate!.day &&
                                        d.month == selectedDate!.month &&
                                        d.year == selectedDate!.year;
                                  }
                                } catch (_) {
                                  return false;
                                }
                              }
                              return false;
                            })();

                        return matchSearch && matchDate;
                      }).toList()
                        ..sort((a, b) {
                          final aTime = a['created_at'] as Timestamp?;
                          final bTime = b['created_at'] as Timestamp?;
                          if (aTime == null || bTime == null) return 0;
                          return bTime.compareTo(aTime);
                        });

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Tidak ada data yang cocok",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index];
                      final platKendaraan = data['plat_kendaraan'] ?? '-';
                      final tanggal = data['tanggal'] ?? '-';
                      final tujuan = data['tujuan_muatan'] ?? '-';
                      final docId = data['id'] ?? '';
                      final kendaraanId = data['kendaraan_id'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A3A7A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    platKendaraan,
                                    textAlign: TextAlign.center,
                                    style:
                                        const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    tanggal,
                                    textAlign: TextAlign.center,
                                    style:
                                        const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    tujuan,
                                    textAlign: TextAlign.center,
                                    style:
                                        const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                    ),
                                    // ─── NAVIGASI KE DETAIL — CEK GPS DULU ───
                                    onPressed: () async {
                                      final locationReady =
                                          await _ensureLocationReady(context);
                                      if (!locationReady) return;

                                      if (!context.mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DetailPerjalananPage(
                                            docId: docId,
                                            currentStatus: activeTab,
                                            kendaraanId: kendaraanId,
                                            data: data,
                                          ),
                                        ),
                                      ).then((_) {
                                        setState(() {});
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}