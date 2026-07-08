import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../database/supabase_service.dart';
import '../../models/jadwal_model.dart';
import '../../models/booking_model.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingDosen = true;
  int? _dosenPembimbingId;
  String? _namaDosenPembimbing;
  List<JadwalModel> _jadwalTersedia = [];
  bool _isLoadingJadwal = false;

  final TextEditingController _keperluanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load data setelah frame pertama render
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInit());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _keperluanController.dispose();
    // Clear selected lecturer for booking on dispose so it doesn't persist
    context.read<BookingProvider>().setSelectedDosenForBooking(null);
    super.dispose();
  }

  /// Load dosen pembimbing + jadwal + booking history (dipisah agar lazy)
  Future<void> _loadInit() async {
    await _loadDosenPembimbing();
    if (_dosenPembimbingId != null) {
      _loadJadwal(); // tidak perlu await - load paralel
    }
    _loadBookingHistory(); // load riwayat booking secara terpisah
  }

  Future<void> _loadDosenPembimbing() async {
    // Check if there is a preselected lecturer in the provider first
    final bookingProvider = context.read<BookingProvider>();
    if (bookingProvider.selectedDosenForBooking != null) {
      final preselected = bookingProvider.selectedDosenForBooking!;
      if (mounted) {
        setState(() {
          _dosenPembimbingId = preselected.id;
          _namaDosenPembimbing = preselected.nama;
          _isLoadingDosen = false;
        });
      }
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingDosen = false);
      return;
    }

    try {
      final supabase = SupabaseService();
      final dosenId = await supabase.getDosenPembimbingByMahasiswa(user.id!);
      if (dosenId != null) {
        final dosen = await supabase.getUserById(dosenId);
        if (mounted) {
          setState(() {
            _dosenPembimbingId = dosenId;
            _namaDosenPembimbing = dosen?.nama ?? 'Dosen Tidak Diketahui';
          });
        }
      }
    } catch (e) {
      // silently fail - tampilkan empty state
    } finally {
      if (mounted) setState(() => _isLoadingDosen = false);
    }
  }

  Future<void> _loadJadwal() async {
    if (_dosenPembimbingId == null) return;
    if (mounted) setState(() => _isLoadingJadwal = true);

    try {
      final supabase = SupabaseService();
      final jadwal = await supabase.getJadwalTersedia(_dosenPembimbingId!);
      if (mounted) setState(() => _jadwalTersedia = jadwal);
    } catch (e) {
      // silently fail
    } finally {
      if (mounted) setState(() => _isLoadingJadwal = false);
    }
  }

  Future<void> _loadBookingHistory() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await context.read<BookingProvider>().fetchBookingByMahasiswa(user.id!);
  }

  Future<void> _refresh() async {
    final user = context.read<AuthProvider>().currentUser;
    await _loadJadwal();
    if (user != null) {
      await context.read<BookingProvider>().fetchBookingByMahasiswa(user.id!, forceRefresh: true);
    }
  }

  void _showBookingDialog(JadwalModel jadwal) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    _keperluanController.clear();

    final primaryColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.event_available, color: primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Buat Jadwal Bimbingan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info jadwal
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.person, _namaDosenPembimbing ?? '-'),
                        const SizedBox(height: 6),
                        _infoRow(Icons.calendar_month, '${jadwal.hari}, ${jadwal.tanggal}'),
                        const SizedBox(height: 4),
                        _infoRow(Icons.access_time, '${jadwal.jamMulai} - ${jadwal.jamSelesai}'),
                        const SizedBox(height: 4),
                        _infoRow(Icons.location_on, jadwal.lokasi),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Keperluan Bimbingan:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keperluanController,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Konsultasi BAB 2, Perbaikan metodologi, dst...',
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (_keperluanController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Keperluan bimbingan harus diisi!'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);

                        final booking = BookingModel(
                          mahasiswaId: user.id!,
                          dosenId: _dosenPembimbingId!,
                          jadwalId: jadwal.id!,
                          tanggal: jadwal.tanggal,
                          keperluan: _keperluanController.text.trim(),
                          status: 'pending',
                          createdAt: DateTime.now().toIso8601String(),
                        );

                        final errorMsg = await context.read<BookingProvider>().createBooking(booking);

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;

                        if (errorMsg == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(child: Text('Booking berhasil! Menunggu persetujuan dosen.')),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          await _refresh();
                          _tabController.animateTo(1); // pindah ke riwayat
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Booking Bimbingan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          tabs: [
            const Tab(icon: Icon(Icons.calendar_today, size: 18), text: 'Jadwal Tersedia'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 18),
                  const SizedBox(width: 6),
                  const Text('Riwayat'),
                  if (bookingProvider.bookingList.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        '${bookingProvider.bookingList.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJadwalTab(primaryColor),
          _buildRiwayatTab(primaryColor, bookingProvider),
        ],
      ),
    );
  }

  Widget _buildJadwalTab(Color primaryColor) {
    if (_isLoadingDosen) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dosenPembimbingId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 72, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text(
                'Dosen Pembimbing Belum Ditentukan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Anda belum memiliki dosen pembimbing.\nSilakan hubungi staf akademik untuk mendapatkan dosen pembimbing.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner dosen pembimbing
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dosen Pembimbing', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text(
                        _namaDosenPembimbing ?? '-',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Jadwal Tersedia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
              IconButton(
                icon: Icon(Icons.refresh, color: primaryColor, size: 20),
                onPressed: _loadJadwal,
                tooltip: 'Refresh jadwal',
              ),
            ],
          ),

          if (_isLoadingJadwal)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_jadwalTersedia.isEmpty)
            _buildEmptyJadwal()
          else
            ..._jadwalTersedia.map((j) => _buildJadwalCard(j, primaryColor)),
        ],
      ),
    );
  }

  Widget _buildEmptyJadwal() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Belum Ada Jadwal Tersedia', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          const SizedBox(height: 8),
          const Text(
            'Dosen pembimbing Anda belum membuat jadwal bimbingan atau semua jadwal sudah penuh.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalCard(JadwalModel jadwal, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.event_available, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${jadwal.hari}, ${jadwal.tanggal}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142))),
                      Text('${jadwal.jamMulai} - ${jadwal.jamSelesai}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Tersedia', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.location_on_outlined, jadwal.lokasi),
            if (jadwal.keterangan != null && jadwal.keterangan!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _infoRow(Icons.info_outline, jadwal.keterangan!),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showBookingDialog(jadwal),
                icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.white),
                label: const Text('Booking Jadwal Ini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatTab(Color primaryColor, BookingProvider bookingProvider) {
    if (bookingProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final bookings = bookingProvider.bookingList;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: bookings.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('Belum Ada Riwayat Booking', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                      const SizedBox(height: 8),
                      const Text(
                        'Anda belum pernah melakukan\nbooking jadwal bimbingan.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (_, i) => _buildRiwayatCard(bookings[i], primaryColor),
            ),
    );
  }

  Widget _buildRiwayatCard(BookingModel b, Color primaryColor) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    String statusDesc;

    switch (b.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = 'Disetujui';
        statusDesc = 'Booking Anda telah disetujui dosen.';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusLabel = 'Ditolak';
        statusDesc = 'Booking Anda ditolak.';
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.pending;
        statusLabel = 'Menunggu';
        statusDesc = 'Menunggu persetujuan dosen.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(statusIcon, color: statusColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.keperluan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142)), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(statusDesc, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withOpacity(0.3))),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _infoRow(Icons.calendar_month_outlined, 'Dibuat: ${_formatDateTime(b.createdAt)}'),
            if (b.catatanStaf != null && b.catatanStaf!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: b.status == 'rejected' ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: b.status == 'rejected' ? Colors.red.shade200 : Colors.green.shade200),
                ),
                child: _infoRow(Icons.comment_outlined, 'Catatan: ${b.catatanStaf}'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String raw) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}
