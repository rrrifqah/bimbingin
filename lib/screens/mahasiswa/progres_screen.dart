import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progres_provider.dart';
import '../../models/progres_model.dart';

class ProgresScreen extends StatefulWidget {
  const ProgresScreen({super.key});

  @override
  State<ProgresScreen> createState() => _ProgresScreenState();
}

class _ProgresScreenState extends State<ProgresScreen> {
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
    await context.read<ProgresProvider>().fetchTahapMahasiswa(user.id!);
  }

  /// Tampilkan dialog upload bukti revisi + ajukan ke dosen
  void _showAjukanDialog(BuildContext context, ProgresModel progres) {
    final TextEditingController catatanController = TextEditingController();
    final primaryColor = Theme.of(context).primaryColor;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload Bukti Revisi',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 18),
                  ),
                  Text(
                    progres.tahapLabel,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF9098B1)),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tuliskan keterangan bahwa revisi sudah dilakukan:',
                    style:
                        TextStyle(fontSize: 13, color: Color(0xFF2D3142)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: catatanController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Sudah perbaiki latar belakang sesuai catatan dosen...',
                      hintStyle: const TextStyle(
                          color: Color(0xFF9098B1), fontSize: 12),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal',
                      style: TextStyle(color: Color(0xFF9098B1))),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (catatanController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Harap isi keterangan revisi!'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          final success = await context
                              .read<ProgresProvider>()
                              .ajukanKeDosen(
                                  progres.id!, catatanController.text.trim());

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${progres.tahapLabel} berhasil diajukan ke dosen!'),
                                backgroundColor:
                                    const Color(0xFF22C55E),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Gagal mengajukan. Coba lagi.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Ajukan ke Dosen',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final progresProvider = context.watch<ProgresProvider>();
    final user = auth.currentUser;
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final tahapList = progresProvider.tahapMahasiswa;
    final accCount = tahapList.where((p) => p.status == 'acc').length;
    final total = tahapList.length;
    final pct = total > 0 ? accCount / total : 0.0;

    final judulSkripsi =
        tahapList.isNotEmpty ? tahapList.first.judulSkripsi : '-';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF9098B1)),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: progresProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            color: Colors.black.withValues(alpha: 0.04),
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
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textDark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"$judulSkripsi"',
                            style: const TextStyle(
                                fontSize: 12,
                                color: textGrey,
                                fontStyle: FontStyle.italic),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.stars_rounded,
                                    color: primaryColor, size: 30),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$accCount dari $total Tahap ACC',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: textDark),
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 6,
                                        backgroundColor:
                                            Colors.grey.shade100,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                primaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildLegend(const Color(0xFF22C55E), 'ACC'),
                              _buildLegend(
                                  const Color(0xFFF59E0B), 'Menunggu'),
                              _buildLegend(
                                  const Color(0xFFEF4444), 'Revisi'),
                              _buildLegend(Colors.grey.shade400, 'Belum'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Timeline Header
                    const Text(
                      'Timeline Tahapan Skripsi',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textDark),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tahap dengan status "Revisi" dapat diajukan kembali ke dosen.',
                      style: TextStyle(fontSize: 11, color: textGrey),
                    ),
                    const SizedBox(height: 16),

                    // Vertical Timeline
                    if (tahapList.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Belum ada data progres.',
                              style: TextStyle(color: textGrey)),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tahapList.length,
                        itemBuilder: (context, index) {
                          final stage = tahapList[index];
                          final isLast = index == tahapList.length - 1;
                          return _buildTimelineCard(
                              context, stage, isLast, primaryColor, accCount);
                        },
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, ProgresModel stage,
      bool isLast, Color primaryColor, int accCount) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (stage.status) {
      case 'acc':
        statusColor = const Color(0xFF22C55E);
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Disetujui (ACC)';
        break;
      case 'revisi':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Revisi';
        break;
      case 'menunggu_konfirmasi':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.pending_rounded;
        statusLabel = 'Menunggu Konfirmasi';
        break;
      default:
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
                    color: stage.status == 'acc'
                        ? const Color(0xFF22C55E)
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
                  color: statusColor.withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
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
                          stage.tahapLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
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

                  // Updated at
                  if (stage.status != 'belum') ...[
                    const SizedBox(height: 4),
                    Text(
                      'Diperbarui: ${_formatDate(stage.updatedAt)}',
                      style:
                          const TextStyle(fontSize: 10, color: Color(0xFF9098B1)),
                    ),
                  ],

                  // Catatan dosen
                  if (stage.catatan != null &&
                      stage.catatan!.isNotEmpty) ...[
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
                                stage.status == 'acc'
                                    ? Icons.rate_review_rounded
                                    : Icons.warning_amber_rounded,
                                size: 14,
                                color: statusColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                stage.status == 'acc'
                                    ? 'Catatan Dosen'
                                    : 'Revisi Dibutuhkan',
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
                            stage.catatan!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2D3142),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Catatan mahasiswa (jika sudah diajukan)
                  if (stage.status == 'menunggu_konfirmasi' &&
                      stage.catatanMahasiswa != null &&
                      stage.catatanMahasiswa!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bukti revisi Anda:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stage.catatanMahasiswa!,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF2D3142)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // --- FITUR 4: Tombol Upload Bukti Revisi ---
                  if (stage.status == 'revisi') ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showAjukanDialog(context, stage),
                        icon: const Icon(Icons.upload_rounded,
                            size: 16, color: Colors.white),
                        label: const Text(
                          'Upload Bukti & Ajukan ke Dosen',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
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
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 9, color: Color(0xFF9098B1))),
      ],
    );
  }

  String _formatDate(String isoDate) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }
}
