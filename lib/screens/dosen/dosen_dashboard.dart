import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bimbingan_provider.dart';
import '../../models/booking.dart';
import '../../models/student.dart';
import 'dosen_main.dart';

class DosenDashboard extends StatelessWidget {
  const DosenDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BimbinganProvider>();
    final lecturer = provider.currentLecturer;
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    if (lecturer == null) {
      return const Scaffold(
        body: Center(child: Text('Data Dosen Tidak Ditemukan')),
      );
    }

    // Filter bookings for this lecturer
    final lecturerBookings = provider.bookings.where((b) => b.lecturerId == lecturer.id).toList();
    
    // Count statistics
    final activeCount = lecturerBookings.where((b) => b.status == 'Approved').length;
    final pendingCount = lecturerBookings.where((b) => b.status == 'Pending').length;
    final completedCount = lecturerBookings.where((b) => b.status == 'Completed').length;

    // Filter today's bimbingan (status == 'Approved')
    final approvedAgenda = lecturerBookings.where((b) => b.status == 'Approved').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
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
                          style: TextStyle(fontSize: 16, color: textGrey, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          lecturer.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'NIP: ${lecturer.id} | ${lecturer.department}',
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

              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.calendar_today_rounded,
                      iconColor: primaryColor,
                      count: activeCount.toString(),
                      label: 'Jadwal Aktif',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.hourglass_top_rounded,
                      iconColor: Colors.orange,
                      count: pendingCount.toString(),
                      label: 'Menunggu Staf',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: Colors.green,
                      count: completedCount.toString(),
                      label: 'Selesai',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Title Section: Agenda Bimbingan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Agenda Bimbingan Aktif',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to Daftar Bimbingan Screen (Index 1)
                      final parentState = context.findAncestorStateOfType<DosenMainState>();
                      if (parentState != null) {
                        parentState.setIndex(1);
                      }
                    },
                    child: Text('Lihat Semua', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Agenda List
              if (approvedAgenda.isEmpty)
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
                      Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        'Tidak ada agenda aktif saat ini.\nSemua bimbingan selesai atau kosong.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textGrey, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: approvedAgenda.length,
                  itemBuilder: (context, index) {
                    final booking = approvedAgenda[index];
                    // Find student details
                    final student = provider.students.firstWhere(
                      (s) => s.id == booking.studentId,
                      orElse: () => Student(
                        id: booking.studentId,
                        name: 'Mahasiswa',
                        department: '',
                        thesisTitle: '',
                        advisorId: '',
                        daysWaiting: 0,
                        daysRemaining: 0,
                        progress: [],
                      ),
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade100, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: primaryColor.withOpacity(0.1),
                                child: Text(
                                  student.name.isNotEmpty ? student.name[0] : 'M',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark),
                                    ),
                                    Text(
                                      'NIM: ${student.id} | ${student.department}',
                                      style: const TextStyle(fontSize: 11, color: textGrey),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Disetujui',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: textGrey),
                              const SizedBox(width: 6),
                              Text(booking.date, style: const TextStyle(fontSize: 12, color: textDark, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 16),
                              const Icon(Icons.access_time_rounded, size: 14, color: textGrey),
                              const SizedBox(width: 6),
                              Text(booking.timeSlot, style: const TextStyle(fontSize: 12, color: textDark, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.notes_rounded, size: 14, color: textGrey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Bahasan: ${booking.purpose}',
                                  style: const TextStyle(fontSize: 12, color: textDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Move to list to view student progress details
                                    final parentState = context.findAncestorStateOfType<DosenMainState>();
                                    if (parentState != null) {
                                      parentState.setIndex(1);
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryColor,
                                    side: BorderSide(color: primaryColor.withOpacity(0.5)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Lihat Progres Skripsi'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    provider.validateAttendance(booking.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Kehadiran bimbingan berhasil divalidasi!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Validasi Hadir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
            ],
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
            color: Colors.black.withOpacity(0.04),
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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF9098B1), fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
