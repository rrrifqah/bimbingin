import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';

/// Halaman untuk Dosen mengelola permintaan booking dari mahasiswa bimbingannya.
class BookingDosenScreen extends StatefulWidget {
  const BookingDosenScreen({super.key});

  @override
  State<BookingDosenScreen> createState() => _BookingDosenScreenState();
}

class _BookingDosenScreenState extends State<BookingDosenScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      _dataLoaded = true;
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await context.read<BookingProvider>().fetchBookingByDosen(user.id!, forceRefresh: forceRefresh);
  }

  Future<void> _approveBooking(BookingModel booking) async {
    final result = await context.read<BookingProvider>().updateStatusBooking(
      booking.id!,
      'approved',
      null,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Booking disetujui!' : 'Gagal menyetujui booking.'),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectBooking(BookingModel booking) async {
    final TextEditingController catatanCtrl = TextEditingController();
    final primaryColor = Theme.of(context).primaryColor;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool isSubmitting = false;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Tolak Booking', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mahasiswa: ${booking.namaMahasiswa ?? 'ID ${booking.mahasiswaId}'}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                const Text('Alasan penolakan (opsional):', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: catatanCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan alasan penolakan...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        final result = await context.read<BookingProvider>().updateStatusBooking(
                          booking.id!,
                          'rejected',
                          catatanCtrl.text.trim().isEmpty ? null : catatanCtrl.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result ? 'Booking ditolak.' : 'Gagal menolak booking.'),
                            backgroundColor: result ? Colors.orange : Colors.red,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Tolak', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final bookingProvider = context.watch<BookingProvider>();
    final allBookings = bookingProvider.bookingList;

    // Pisahkan pending dan riwayat
    final pendingList = allBookings.where((b) => b.status == 'pending').toList();
    final riwayatList = allBookings.where((b) => b.status != 'pending').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Permintaan Booking',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
            ),
            if (pendingList.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pendingList.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: primaryColor),
            onPressed: () => _loadData(forceRefresh: true),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pending_actions, size: 18),
                  const SizedBox(width: 6),
                  const Text('Menunggu'),
                  if (pendingList.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(8)),
                      child: Text('${pendingList.length}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(icon: Icon(Icons.history, size: 18), text: 'Riwayat'),
          ],
        ),
      ),
      body: bookingProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(pendingList, primaryColor),
                _buildRiwayatTab(riwayatList, primaryColor),
              ],
            ),
    );
  }

  Widget _buildPendingTab(List<BookingModel> list, Color primaryColor) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Tidak Ada Permintaan Booking', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            const SizedBox(height: 8),
            const Text('Semua permintaan sudah ditangani.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _buildPendingCard(list[i], primaryColor),
      ),
    );
  }

  Widget _buildPendingCard(BookingModel b, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Text(
                    (b.namaMahasiswa ?? 'M').isNotEmpty ? (b.namaMahasiswa ?? 'M')[0].toUpperCase() : 'M',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.namaMahasiswa ?? 'Mahasiswa ID ${b.mahasiswaId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142))),
                      Text('Dibuat: ${_formatDateTime(b.createdAt)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Menunggu', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Keperluan:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(b.keperluan, style: const TextStyle(fontSize: 13, color: Color(0xFF2D3142))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectBooking(b),
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    label: const Text('Tolak', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveBooking(b),
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: const Text('Setujui', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatTab(List<BookingModel> list, Color primaryColor) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Belum Ada Riwayat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final b = list[i];
          final isApproved = b.status == 'approved';
          final statusColor = isApproved ? Colors.green : Colors.red;
          final statusLabel = isApproved ? 'Disetujui' : 'Ditolak';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(isApproved ? Icons.check_circle : Icons.cancel, color: statusColor, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.namaMahasiswa ?? 'Mahasiswa ID ${b.mahasiswaId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(b.keperluan, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (b.catatanStaf != null && b.catatanStaf!.isNotEmpty)
                          Text('Catatan: ${b.catatanStaf}', style: const TextStyle(fontSize: 11, color: Colors.red)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
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
