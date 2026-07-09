import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../database/supabase_service.dart';
import '../../models/booking_model.dart';
import '../../models/jadwal_model.dart';
import 'kelola_mahasiswa_screen.dart';
import 'kelola_jadwal_screen.dart';
//import 'kelola_dosen_screen.dart';//
import 'atur_pembimbing_screen.dart';
import '../../models/user_model.dart';

/// Dashboard Staff — Diubah menjadi Dashboard Monitoring Realtime.
/// Menampilkan jadwal dosen aktif beserta antrian mahasiswa FCFS.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  final SupabaseService _service = SupabaseService();

  int _totalDosen = 0;
  int _totalMahasiswa = 0;
  int _jadwalHariIni = 0;
  int _bookingHariIni = 0;

  RealtimeChannel? _bookingChannel;
  RealtimeChannel? _jadwalChannel;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtime();
  }

  @override
  void dispose() {
    final client = Supabase.instance.client;
    if (_bookingChannel != null) {
      client.removeChannel(_bookingChannel!);
    }
    if (_jadwalChannel != null) {
      client.removeChannel(_jadwalChannel!);
    }
    super.dispose();
  }

  /// Setup listeners untuk Supabase Realtime agar dashboard langsung update
  void _setupRealtime() {
    final client = Supabase.instance.client;

    _bookingChannel = client.channel('public-booking-changes-dashboard').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'booking',
      callback: (payload) {
        if (mounted) {
          _loadData();
        }
      },
    );
    _bookingChannel?.subscribe();

    _jadwalChannel = client.channel('public-jadwal-changes-dashboard').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'jadwal_dosen',
      callback: (payload) {
        if (mounted) {
          _loadData();
        }
      },
    );
    _jadwalChannel?.subscribe();
  }

  /// Memuat data jadwal dan booking
  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final results = await Future.wait([
        _service.getMonitoringJadwal(),
        _service.getMonitoringBookings(),
        _service.getAllDosen(),
        _service.getAllMahasiswa(),
      ]);

      final schedules = results[0] as List<Map<String, dynamic>>;
      final bookings = results[1] as List<Map<String, dynamic>>;
      final dosenList = results[2] as List<Map<String, dynamic>>;
      final mahasiswaList = results[3] as List<UserModel>;

      final jadwalHariIni = schedules.where((s) => s['tanggal'] == todayStr).length;

      // Hitung booking hari ini (booking yang jadwalnya hari ini)
      int bookingHariIni = 0;
      for (final b in bookings) {
        final jId = b['jadwal_id'] as int?;
        if (jId != null) {
          final sched = schedules.firstWhere((s) => s['id'] == jId, orElse: () => {});
          if (sched.isNotEmpty && sched['tanggal'] == todayStr) {
            bookingHariIni++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _schedules = schedules;
          _bookings = bookings;
          _totalDosen = dosenList.length;
          _totalMahasiswa = mahasiswaList.length;
          _jadwalHariIni = jadwalHariIni;
          _bookingHariIni = bookingHariIni;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Update status booking (Approved / Rejected)
  Future<void> _updateBookingStatus(int bookingId, String status, int jadwalId) async {
    try {
      await _service.updateStatusBooking(bookingId, status, null);

      // Sinkronisasi status penuh di tabel jadwal_dosen jika slot sudah terpenuhi
      final schedule = _schedules.firstWhere((s) => s['id'] == jadwalId);
      final activeForJadwal = _bookings.where((b) => b['jadwal_id'] == jadwalId && b['status'] != 'rejected').toList();
      
      final startParts = schedule['jam_mulai'].toString().split(':');
      final endParts = schedule['jam_selesai'].toString().split(':');
      final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final duration = endMin - startMin;
      int totalSlots = 3;
      if (duration > 0) {
        totalSlots = (duration / 30).floor();
        if (totalSlots <= 0) totalSlots = 1;
      }

      if (status == 'rejected') {
        if (activeForJadwal.length - 1 < totalSlots) {
          await _service.updateStatusJadwal(jadwalId, 'tersedia');
        }
      } else if (status == 'approved') {
        if (activeForJadwal.length >= totalSlots) {
          await _service.updateStatusJadwal(jadwalId, 'penuh');
        }
      }

      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'approved' ? 'Booking berhasil disetujui!' : 'Booking berhasil ditolak!'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.orange,
          ),
        );
      }
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

  /// Hitung total slot secara dinamis berdasarkan jam mulai & selesai
  int _calculateTotalSlots(String jamMulai, String jamSelesai) {
    try {
      final startParts = jamMulai.split(':');
      final endParts = jamSelesai.split(':');
      final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final duration = endMin - startMin;
      if (duration <= 0) return 1;
      final slots = (duration / 30).floor();
      return slots > 0 ? slots : 1;
    } catch (_) {
      return 3;
    }
  }

  /// Menghitung jam bimbingan untuk urutan FCFS (30 menit per slot)
  String _calculateJamBimbingan(String jamMulai, int index) {
    try {
      final parts = jamMulai.split(':');
      final startMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final slotMin = startMin + (index * 30);
      final hours = (slotMin ~/ 60).toString().padLeft(2, '0');
      final mins = (slotMin % 60).toString().padLeft(2, '0');
      
      final endSlotMin = slotMin + 30;
      final endHours = (endSlotMin ~/ 60).toString().padLeft(2, '0');
      final endMins = (endSlotMin % 60).toString().padLeft(2, '0');
      
      return "$hours:$mins - $endHours:$endMins";
    } catch (_) {
      return jamMulai;
    }
  }

  /// Format waktu booking
  String _formatWaktuBooking(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final formatter = DateFormat('dd MMM yyyy, HH:mm');
      return formatter.format(dt);
    } catch (_) {
      return createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Dashboard Monitoring',
          style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: primaryColor),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Welcome Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${user?.nama ?? 'Staf'}! 👋',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sistem Monitoring Jadwal Dosen & Antrian Booking Mahasiswa (Realtime)',
                    style: TextStyle(fontSize: 12, color: textGrey.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _schedules.isEmpty
                      ? const Center(
                          child: Text('Belum ada jadwal dosen yang dibuka.', style: TextStyle(color: textGrey)),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _schedules.length,
                            itemBuilder: (context, index) {
                              final schedule = _schedules[index];
                              final scheduleId = schedule['id'] as int;

                              // Hitung slot
                              final totalSlots = _calculateTotalSlots(
                                schedule['jam_mulai'] ?? '09:00',
                                schedule['jam_selesai'] ?? '11:00',
                              );

                              // Ambil seluruh booking untuk jadwal ini
                              final bookingsForJadwal = _bookings
                                  .where((b) => b['jadwal_id'] == scheduleId)
                                  .toList();

                              // Booking aktif (bukan ditolak) untuk menghitung okupansi
                              final activeBookings = bookingsForJadwal
                                  .where((b) => b['status'] != 'rejected')
                                  .toList();

                              final slotTerisi = activeBookings.length;
                              final slotTersisa = totalSlots - slotTerisi >= 0 ? totalSlots - slotTerisi : 0;

                              // Menentukan status jadwal
                              String statusLabel = 'Belum Dibuka';
                              Color statusColor = Colors.grey;
                              final dbStatus = schedule['status'] as String? ?? 'tersedia';

                              if (dbStatus == 'penuh' || slotTerisi >= totalSlots) {
                                statusLabel = 'Penuh';
                                statusColor = Colors.red;
                              } else if (dbStatus == 'tersedia') {
                                statusLabel = 'Masih Tersedia';
                                statusColor = Colors.green;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Theme(
                                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    initiallyExpanded: true,
                                    title: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: primaryColor.withOpacity(0.1),
                                          child: Text(
                                            (schedule['dosen']?['nama'] ?? 'D')[0].toUpperCase(),
                                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                schedule['dosen']?['nama'] ?? 'Dosen',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${schedule['hari']}, ${schedule['tanggal']} (${schedule['jam_mulai']} - ${schedule['jam_selesai']})',
                                                style: const TextStyle(fontSize: 12, color: textGrey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  statusLabel,
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Slot: $slotTerisi/$totalSlots',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                                          ),
                                        ],
                                      ),
                                    ),
                                    children: [
                                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Daftar Antrian Mahasiswa (FCFS):',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
                                            ),
                                            const SizedBox(height: 10),
                                            if (bookingsForJadwal.isEmpty)
                                              const Padding(
                                                padding: EdgeInsets.symmetric(vertical: 12),
                                                child: Center(
                                                  child: Text(
                                                    'Belum ada mahasiswa yang melakukan booking.',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                                                  ),
                                                ),
                                              )
                                            else
                                              ...bookingsForJadwal.asMap().entries.map((entry) {
                                                final bookingIndex = entry.key;
                                                final booking = entry.value;

                                                // Nomor antrian didasarkan pada urutan booking aktif
                                                final activeIndex = activeBookings.indexWhere((b) => b['id'] == booking['id']);
                                                final isRejected = booking['status'] == 'rejected';

                                                String queueText = isRejected ? '-' : 'Booking #${activeIndex + 1}';
                                                String bimbinganTime = isRejected
                                                    ? '-'
                                                    : _calculateJamBimbingan(schedule['jam_mulai'] ?? '09:00', activeIndex);

                                                Color badgeCol;
                                                String badgeLab;
                                                switch (booking['status'].toString().toLowerCase()) {
                                                  case 'approved':
                                                    badgeCol = Colors.green;
                                                    badgeLab = 'Disetujui';
                                                    break;
                                                  case 'rejected':
                                                    badgeCol = Colors.red;
                                                    badgeLab = 'Ditolak';
                                                    break;
                                                  default:
                                                    badgeCol = Colors.orange;
                                                    badgeLab = 'Menunggu';
                                                }

                                                return Container(
                                                  margin: const EdgeInsets.only(bottom: 12),
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF9FAFC),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: const Color(0xFFECEFF5)),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            queueText,
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 12,
                                                              color: isRejected ? Colors.grey : primaryColor,
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: badgeCol.withOpacity(0.1),
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: Text(
                                                              badgeLab,
                                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeCol),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        booking['mahasiswa']?['nama'] ?? 'Mahasiswa',
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
                                                      ),
                                                      Text(
                                                        'NIM: ${booking['mahasiswa']?['nim_nip'] ?? "-"}',
                                                        style: const TextStyle(fontSize: 11, color: textGrey),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.access_time_rounded, size: 12, color: textGrey),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'Booking: ${_formatWaktuBooking(booking['created_at'])}',
                                                            style: const TextStyle(fontSize: 11, color: textGrey),
                                                          ),
                                                        ],
                                                      ),
                                                      if (!isRejected) ...[
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            const Icon(Icons.school_outlined, size: 12, color: textGrey),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              'Bimbingan: $bimbinganTime',
                                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textDark),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Icon(Icons.info_outline, size: 12, color: textGrey),
                                                          const SizedBox(width: 4),
                                                          Expanded(
                                                            child: Text(
                                                              'Keperluan: ${booking['keperluan'] ?? "-"}',
                                                              style: const TextStyle(fontSize: 11, color: textGrey),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      
                                                      // Action Buttons for Pending Booking
                                                      if (booking['status'] == 'pending') ...[
                                                        const SizedBox(height: 12),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                          children: [
                                                            TextButton.icon(
                                                              onPressed: () => _updateBookingStatus(booking['id'], 'rejected', scheduleId),
                                                              icon: const Icon(Icons.clear, color: Colors.red, size: 16),
                                                              label: const Text('Tolak', style: TextStyle(color: Colors.red, fontSize: 12)),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            ElevatedButton.icon(
                                                              onPressed: () => _updateBookingStatus(booking['id'], 'approved', scheduleId),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: Colors.green,
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                                elevation: 0,
                                                              ),
                                                              icon: const Icon(Icons.check, color: Colors.white, size: 16),
                                                              label: const Text('Setujui', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                                            ),
                                                          ],
                                                        )
                                                      ]
                                                    ],
                                                  ),
                                                );
                                              }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
