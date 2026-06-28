import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/bimbingan_provider.dart';
import '../../models/student.dart';
import '../../models/booking.dart';

class DaftarBimbinganScreen extends StatelessWidget {
  const DaftarBimbinganScreen({super.key});

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

    // Filter students under this advisor
    final advisees = provider.students.where((s) => s.advisorId == lecturer.id).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Daftar Mahasiswa Bimbingan',
          style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: advisees.isEmpty
          ? const Center(
              child: Text(
                'Belum ada mahasiswa bimbingan yang terdaftar.',
                style: TextStyle(color: textGrey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: advisees.length,
              itemBuilder: (context, index) {
                final student = advisees[index];

                // Find active approved booking for this student with this lecturer
                final studentBookings = provider.bookings
                    .where((b) => b.studentId == student.id && b.lecturerId == lecturer.id && b.status == 'Approved')
                    .toList();

                final hasApprovedBooking = studentBookings.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                      // Student Basic Info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: primaryColor.withOpacity(0.1),
                            child: Text(
                              student.name[0],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                                Text(
                                  'NIM: ${student.id} | ${student.department}',
                                  style: const TextStyle(fontSize: 11, color: textGrey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Thesis Topic Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Topik Skripsi:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: textGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '"${student.thesisTitle}"',
                              style: const TextStyle(
                                fontSize: 13,
                                color: textDark,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Display active approved meeting schedule if any
                      if (hasApprovedBooking) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bimbingan Aktif: ${studentBookings.first.date} @ ${studentBookings.first.timeSlot}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showProgressBottomSheet(context, student),
                              icon: Icon(Icons.analytics_outlined, size: 16, color: primaryColor),
                              label: const Text('Lihat Progres'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: BorderSide(color: primaryColor.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          if (hasApprovedBooking) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  provider.validateAttendance(studentBookings.first.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Kehadiran ${student.name} berhasil divalidasi!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check, size: 16, color: Colors.white),
                                label: const Text('Validasi Hadir'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showProgressBottomSheet(BuildContext context, Student student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFF4F7FB),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Bottom sheet handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progres Skripsi: ${student.name}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          Text(
                            'NIM: ${student.id}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF9098B1)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Timeline body
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: student.progress.length,
                  itemBuilder: (context, index) {
                    final stage = student.progress[index];
                    final isLast = index == student.progress.length - 1;

                    Color statusColor;
                    IconData statusIcon;

                    switch (stage.status) {
                      case 'ACC':
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                        break;
                      case 'Revisi':
                        statusColor = Colors.red;
                        statusIcon = Icons.cancel;
                        break;
                      case 'Pending':
                        statusColor = Colors.orange;
                        statusIcon = Icons.pending;
                        break;
                      default:
                        statusColor = Colors.grey.shade400;
                        statusIcon = Icons.circle_outlined;
                    }

                    return IntrinsicHeight(
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Icon(statusIcon, color: statusColor, size: 20),
                              if (!isLast)
                                Expanded(
                                  child: Container(width: 2, color: Colors.grey.shade300),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        stage.chapterName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF2D3142),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          stage.status,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (stage.status != 'Belum Mulai') ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Diperbarui: ${DateFormat('dd MMM yyyy').format(stage.lastUpdated)}',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF9098B1)),
                                    ),
                                  ],
                                  if (stage.status != 'Belum Mulai' && stage.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        stage.notes,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF2D3142)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
