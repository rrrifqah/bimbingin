import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/bimbingan_provider.dart';

class ProgresScreen extends StatelessWidget {
  const ProgresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BimbinganProvider>();
    final student = provider.currentStudent;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    if (student == null) {
      return const Scaffold(
        body: Center(child: Text('Data Mahasiswa Tidak Ditemukan')),
      );
    }

    final totalChapters = student.progress.length;
    final completedChapters = student.progress.where((p) => p.status == 'ACC').length;
    final progressPercent = totalChapters > 0 ? (completedChapters / totalChapters) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Progres Skripsi',
          style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Summary Card
            Container(
              padding: const EdgeInsets.all(20),
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
                  const Text(
                    'Ringkasan Capaian',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pantau progres verifikasi bab skripsi Anda.',
                    style: TextStyle(fontSize: 12, color: textGrey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.stars_rounded, color: Theme.of(context).primaryColor, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$completedChapters dari $totalChapters Bab ACC',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressPercent,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade100,
                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Timeline Header
            const Text(
              'Timeline Tahapan Skripsi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 16),

            // Vertical Timeline List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: student.progress.length,
              itemBuilder: (context, index) {
                final stage = student.progress[index];
                final isLast = index == student.progress.length - 1;

                Color statusColor;
                IconData statusIcon;
                String statusLabel;

                switch (stage.status) {
                  case 'ACC':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle_rounded;
                    statusLabel = 'Disetujui (ACC)';
                    break;
                  case 'Revisi':
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel_rounded;
                    statusLabel = 'Revisi';
                    break;
                  case 'Pending':
                    statusColor = Colors.orange;
                    statusIcon = Icons.pending_rounded;
                    statusLabel = 'Ditinjau';
                    break;
                  default: // 'Belum Mulai'
                    statusColor = Colors.grey.shade400;
                    statusIcon = Icons.circle_outlined;
                    statusLabel = 'Belum Mulai';
                }

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line and Dot indicator
                      Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Icon(statusIcon, color: statusColor, size: 24),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: index < completedChapters 
                                    ? Colors.green 
                                    : Colors.grey.shade300,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Card Content
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: stage.status == 'Revisi' 
                                  ? Colors.red.shade100 
                                  : (stage.status == 'ACC' ? Colors.green.shade50 : Colors.grey.shade100),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      stage.chapterName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textDark,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              
                              // Last updated
                              if (stage.status != 'Belum Mulai')
                                Text(
                                  'Diperbarui: ${DateFormat('dd MMM yyyy, HH:mm').format(stage.lastUpdated)}',
                                  style: const TextStyle(fontSize: 10, color: textGrey),
                                ),
                              
                              if (stage.status != 'Belum Mulai' && stage.notes.isNotEmpty) ...[
                                const SizedBox(height: 12),
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
                                      Row(
                                        children: [
                                          Icon(
                                            stage.status == 'ACC' 
                                                ? Icons.rate_review_rounded 
                                                : Icons.warning_amber_rounded,
                                            size: 14,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            stage.status == 'ACC' ? 'Catatan Dosen' : 'Revisi Dibutuhkan',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        stage.notes,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: textDark,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
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
          ],
        ),
      ),
    );
  }
}
