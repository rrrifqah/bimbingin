import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bimbingan_provider.dart';
import '../../models/student.dart';
import '../../models/booking.dart';
import '../../models/lecturer.dart';
import 'mahasiswa_main.dart';

class MahasiswaDashboard extends StatelessWidget {
  const MahasiswaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BimbinganProvider>();
    final student = provider.currentStudent;
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    if (student == null) {
      return const Scaffold(
        body: Center(child: Text('Data Mahasiswa Tidak Ditemukan')),
      );
    }

    // Find student's lecturer
    final advisor = provider.lecturers.firstWhere(
      (l) => l.id == student.advisorId,
      orElse: () => provider.lecturers.first,
    );

    // Get upcoming booking (status: Approved or Pending)
    final upcomingBookings = provider.bookings.where(
      (b) => b.studentId == student.id && (b.status == 'Approved' || b.status == 'Pending'),
    ).toList();
    
    final hasUpcoming = upcomingBookings.isNotEmpty;
    final latestBooking = hasUpcoming ? upcomingBookings.first : null;

    // Calculate completed chapters percentage
    final completedChapters = student.progress.where((p) => p.status == 'ACC').length;
    final totalChapters = student.progress.length;
    final progressPercent = totalChapters > 0 ? (completedChapters / totalChapters) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Halo 👋,',
                          style: TextStyle(fontSize: 16, color: textGrey, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          student.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'NIM: ${student.id} | ${student.department}',
                          style: const TextStyle(fontSize: 12, color: textGrey),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      provider.logout();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title of thesis
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Judul Skripsi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${student.thesisTitle}"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.white.withOpacity(0.3), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pembimbing: ${advisor.name}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Statistics Section
              const Text(
                'Statistik Skripsi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.timer_outlined,
                      iconColor: Colors.orange,
                      title: 'Menunggu',
                      value: '${student.daysWaiting} Hari',
                      subtitle: 'Sejak Booking Terakhir',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.hourglass_empty_rounded,
                      iconColor: Colors.red,
                      title: 'Sisa Waktu',
                      value: '${student.daysRemaining} Hari',
                      subtitle: 'Hingga Target Sidang',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Upcoming Schedule
              const Text(
                'Jadwal Bimbingan Mendatang',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 12),
              _buildUpcomingCard(context, latestBooking, advisor, primaryColor),

              const SizedBox(height: 24),

              // Thesis progress bar card
              const Text(
                'Progres Bimbingan Bab',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completedChapters dari $totalChapters Bab Selesai (ACC)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
                        ),
                        Text(
                          '${(progressPercent * 100).toInt()}%',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Small list of status indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: student.progress.map((p) {
                        Color dotColor = Colors.grey;
                        if (p.status == 'ACC') dotColor = Colors.green;
                        if (p.status == 'Revisi') dotColor = Colors.red;
                        if (p.status == 'Pending') dotColor = Colors.orange;

                        return Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.chapterName.split(':')[0],
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textDark),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9098B1), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: Color(0xFF9098B1)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context, Booking? booking, Lecturer advisor, Color primaryColor) {
    if (booking == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_month_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text(
              'Belum ada jadwal bimbingan aktif.',
              style: TextStyle(fontSize: 13, color: Color(0xFF9098B1), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                final rootState = context.findAncestorStateOfType<MahasiswaMainState>();
                if (rootState != null) {
                  rootState.setIndex(1); // Booking Tab
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: const Text('Buat Booking Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    Color statusColor = Colors.orange;
    if (booking.status == 'Approved') statusColor = Colors.green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: booking.status == 'Approved' ? Colors.green.shade100 : Colors.orange.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: booking.status == 'Approved' ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.status == 'Approved' ? 'Disetujui' : 'Menunggu Staf',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              Text(
                booking.id,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9098B1)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(advisor.avatarUrl),
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advisor.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142), fontSize: 14),
                    ),
                    Text(
                      advisor.department,
                      style: const TextStyle(color: Color(0xFF9098B1), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF9098B1)),
              const SizedBox(width: 8),
              Text(
                booking.date,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF9098B1)),
              const SizedBox(width: 8),
              Text(
                booking.timeSlot,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF9098B1)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Keperluan: ${booking.purpose}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF2D3142)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
