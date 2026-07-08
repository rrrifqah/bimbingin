import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/target_provider.dart';
import '../../database/supabase_service.dart';
import '../../models/user_model.dart';
import '../../models/booking_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BookingModel> _allBooking = [];
  bool _isLoading = false;
  final SupabaseService _dbHelper = SupabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBooking();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      _allBooking = await _dbHelper.getAllBooking();
    } catch (e) {
      _allBooking = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateStatus(
      int id, String status, String? catatan) async {
    try {
      await _dbHelper.updateStatusBooking(id, status, catatan);
      await _loadBooking();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui status booking.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    final pendingList = _allBooking.where((b) => b.status == 'pending').toList();
    final approvedList =
        _allBooking.where((b) => b.status == 'approved').toList();
    final historyList = _allBooking
        .where((b) => b.status == 'rejected' || b.status == 'completed')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kelola Booking Bimbingan',
          style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF9098B1)),
            onPressed: _loadBooking,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: textGrey,
          indicatorColor: primaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Antrian'),
                  if (pendingList.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${pendingList.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const Tab(text: 'Disetujui'),
            const Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${user?.nama ?? 'Staf'}! 👋',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Persetujuan jadwal bimbingan masuk dari mahasiswa.',
                    style: TextStyle(fontSize: 12, color: textGrey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBookingList(context, pendingList,
                            showActions: true),
                        _buildBookingList(context, approvedList,
                            showActions: false),
                        _buildBookingList(context, historyList,
                            showActions: false),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(BuildContext context, List<BookingModel> list,
      {required bool showActions}) {
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada data booking di tab ini.',
              style: TextStyle(color: textGrey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final booking = list[index];

        Color badgeColor;
        String badgeLabel;
        switch (booking.status.toLowerCase()) {
          case 'approved':
            badgeColor = Colors.green;
            badgeLabel = 'Disetujui';
            break;
          case 'rejected':
            badgeColor = Colors.red;
            badgeLabel = 'Ditolak';
            break;
          case 'completed':
            badgeColor = Colors.blue;
            badgeLabel = 'Selesai';
            break;
          default:
            badgeColor = Colors.orange;
            badgeLabel = 'Menunggu';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: booking.status == 'pending'
                  ? Colors.orange.shade100
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  Text(
                    '#${booking.id}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textGrey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Mahasiswa
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      booking.namaMahasiswa != null &&
                              booking.namaMahasiswa!.isNotEmpty
                          ? booking.namaMahasiswa![0]
                          : 'M',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.namaMahasiswa ?? 'Mahasiswa',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textDark,
                              fontSize: 14),
                        ),
                        Text(
                          booking.nim != null ? 'NIM: ${booking.nim}' : '',
                          style:
                              const TextStyle(color: textGrey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 14, color: textGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Dosen: ${booking.namaDosen ?? '-'}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: textDark,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: textGrey),
                  const SizedBox(width: 6),
                  Text(
                    'Tanggal: ${booking.tanggal ?? '-'} @ ${booking.jam ?? '-'}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: textDark,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: textGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Keperluan: ${booking.keperluan}',
                      style:
                          const TextStyle(fontSize: 12, color: textDark),
                    ),
                  ),
                ],
              ),

              if (booking.catatanStaf != null &&
                  booking.catatanStaf!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_rounded,
                        size: 14, color: textGrey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Catatan: ${booking.catatanStaf}',
                        style: const TextStyle(
                            fontSize: 12, color: textGrey),
                      ),
                    ),
                  ],
                ),
              ],

              if (showActions) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await _updateStatus(booking.id!, 'rejected', null);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Booking ditolak.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Tolak'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _updateStatus(
                              booking.id!, 'approved', null);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Booking disetujui.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Terima',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
