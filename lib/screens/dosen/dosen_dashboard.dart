import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progres_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/jadwal_provider.dart';
import 'dosen_main.dart';

class DosenDashboard extends StatefulWidget {
  const DosenDashboard({super.key});

  @override
  State<DosenDashboard> createState() => _DosenDashboardState();
}

class _DosenDashboardState extends State<DosenDashboard> {
  bool _dataLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      _dataLoaded = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await Future.wait([
      context.read<ProgresProvider>().fetchTahapGroupedByMahasiswaForDosen(user.id!),
      context.read<BookingProvider>().fetchBookingByDosen(user.id!),
      context.read<JadwalProvider>().fetchJadwalDosen(user.id!),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final progresProvider = context.watch<ProgresProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final jadwalProvider = context.watch<JadwalProvider>();
    
    final user = auth.currentUser;
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final grouped = progresProvider.tahapGroupedByMahasiswa;
    final totalMahasiswa = grouped.keys.length;
    final menungguCount = progresProvider.menungguKonfirmasiCount;
    
    // Hitung permintaan booking pending
    final listBooking = bookingProvider.bookingList;
    final pendingBookingCount = listBooking.where((b) => b.status == 'pending').length;
    
    // Limit to recent 3 bookings
    final recentBookings = listBooking.where((b) => b.status == 'pending').take(3).toList();

    // Hitung total progres keseluruhan
    int totalAcc = 0, totalTahap = 0;
    for (final list in grouped.values) {
      totalAcc += list.where((p) => p.status == 'acc').length;
      totalTahap += list.length;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Halo 👋,',
                            style: TextStyle(
                                fontSize: 16,
                                color: textGrey,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            user.nama,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'NIP: ${user.nimNip} | ${user.jurusan}',
                            style: const TextStyle(
                                fontSize: 12, color: textGrey),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await context.read<AuthProvider>().logout();
                        if (!mounted) return;
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: Colors.redAccent, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        icon: Icons.people_outline_rounded,
                        iconColor: primaryColor,
                        count: totalMahasiswa.toString(),
                        label: 'Mahasiswa\nBimbingan',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        icon: Icons.pending_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        count: menungguCount.toString(),
                        label: 'Menunggu\nKonfirmasi',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: const Color(0xFF22C55E),
                        count: totalAcc.toString(),
                        label: 'Tahap\nACC',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Notifikasi menunggu konfirmasi
                if (menungguCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded,
                            color: Color(0xFFF59E0B), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$menungguCount Tahap Menunggu Konfirmasi',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF59E0B),
                                  fontSize: 14,
                                ),
                              ),
                              const Text(
                                'Mahasiswa sudah mengajukan revisi. Segera tinjau!',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF2D3142)),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final parentState =
                                context.findAncestorStateOfType<DosenMainState>();
                            if (parentState != null) {
                              parentState.setIndex(1);
                            }
                          },
                          child: const Text('Tinjau',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF59E0B))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Permintaan Booking Terbaru
                if (recentBookings.isNotEmpty) ...[
                  const Text(
                    'Permintaan Booking Terbaru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...recentBookings.map((booking) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade100, width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event_available, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    booking.namaMahasiswa ?? 'Mahasiswa ID ${booking.mahasiswaId}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Keperluan: ${booking.keperluan}', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await bookingProvider.updateStatusBooking(booking.id!, 'rejected', 'Ditolak dosen');
                                      _loadData();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    child: const Text('Tolak'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await bookingProvider.updateStatusBooking(booking.id!, 'approved', 'Disetujui dosen');
                                      _loadData();
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text('Setujui', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                ],

                // Jadwal Bimbingan
                const Text(
                  'Jadwal Bimbingan Saya',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 12),
                jadwalProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : jadwalProvider.jadwalList.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: const Text(
                              'Belum ada jadwal yang dibuat.',
                              style: TextStyle(color: textGrey, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: jadwalProvider.jadwalList.take(3).length, // Show up to 3
                            itemBuilder: (context, index) {
                              final jadwal = jadwalProvider.jadwalList[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.calendar_today, color: primaryColor, size: 20),
                                  ),
                                  title: Text('${jadwal.hari}, ${jadwal.tanggal}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text('${jadwal.jamMulai} - ${jadwal.jamSelesai}\nStatus: ${jadwal.status.toUpperCase()}'),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
                const SizedBox(height: 24),

                // Progres Overview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progres Mahasiswa Bimbingan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final parentState =
                            context.findAncestorStateOfType<DosenMainState>();
                        if (parentState != null) {
                          parentState.setIndex(1);
                        }
                      },
                      child: Text('Lihat Semua',
                          style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (progresProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (grouped.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada mahasiswa bimbingan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: textGrey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, index) {
                      final mahasiswaId = grouped.keys.elementAt(index);
                      final tahapList = grouped[mahasiswaId]!;
                      final nama = tahapList.isNotEmpty
                          ? tahapList.first.namaMahasiswa ?? 'Mahasiswa'
                          : 'Mahasiswa';
                      final accC =
                          tahapList.where((p) => p.status == 'acc').length;
                      final totalC = tahapList.length;
                      final pct = totalC > 0 ? accC / totalC : 0.0;
                      final hasMenunggu = tahapList
                          .any((p) => p.status == 'menunggu_konfirmasi');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: hasMenunggu
                              ? Border.all(
                                  color: const Color(0xFFF59E0B), width: 1.5)
                              : Border.all(
                                  color: Colors.green.shade100, width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  primaryColor.withValues(alpha: 0.1),
                              child: Text(
                                nama.isNotEmpty ? nama[0] : 'M',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        nama,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: textDark),
                                      ),
                                      if (hasMenunggu) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF59E0B),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text('!',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 5,
                                      backgroundColor: Colors.grey.shade100,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              primaryColor),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$accC/$totalC tahap ACC (${(pct * 100).toInt()}%)',
                                    style: const TextStyle(
                                        fontSize: 11, color: textGrey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF9098B1),
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
