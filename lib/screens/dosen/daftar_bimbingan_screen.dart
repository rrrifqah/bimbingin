import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progres_provider.dart';
import '../../providers/target_provider.dart';
import '../../models/progres_model.dart';
import 'dosen_main.dart';

class DaftarBimbinganScreen extends StatefulWidget {
  const DaftarBimbinganScreen({super.key});

  @override
  State<DaftarBimbinganScreen> createState() => _DaftarBimbinganScreenState();
}

class _DaftarBimbinganScreenState extends State<DaftarBimbinganScreen> {
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
      context.read<TargetProvider>().fetchAllTargetByDosen(user.id!),
    ]);
  }

  /// Tampilkan bottom sheet progres satu mahasiswa
  void _showProgressBottomSheet(
      BuildContext context, int mahasiswaId, String namaMahasiswa,
      List<ProgresModel> tahapList) {
    final primaryColor = Theme.of(context).primaryColor;
    final accCount = tahapList.where((p) => p.status == 'acc').length;
    final total = tahapList.length;
    final pct = total > 0 ? accCount / total : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.80,
          decoration: const BoxDecoration(
            color: Color(0xFFF4F7FB),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progres: $namaMahasiswa',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          Text(
                            '$accCount dari $total tahap ACC',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF9098B1)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: tahapList.isEmpty
                    ? const Center(
                        child: Text('Belum ada data progres.',
                            style: TextStyle(color: Color(0xFF9098B1))))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: tahapList.length,
                        itemBuilder: (context, index) {
                          final p = tahapList[index];
                          final isLast = index == tahapList.length - 1;
                          return _buildTimelineItemDosen(
                              ctx, p, isLast, mahasiswaId);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineItemDosen(BuildContext ctx, ProgresModel p, bool isLast,
      int mahasiswaId) {
    final primaryColor = Theme.of(ctx).primaryColor;
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (p.status) {
      case 'acc':
        statusColor = const Color(0xFF22C55E);
        statusIcon = Icons.check_circle;
        statusLabel = 'ACC';
        break;
      case 'revisi':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel;
        statusLabel = 'Revisi';
        break;
      case 'menunggu_konfirmasi':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.pending;
        statusLabel = 'Menunggu';
        break;
      default:
        statusColor = Colors.grey.shade400;
        statusIcon = Icons.circle_outlined;
        statusLabel = 'Belum';
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
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          p.tahapLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (p.status != 'belum') ...[
                    const SizedBox(height: 4),
                    Text(
                      'Diperbarui: ${_formatDate(p.updatedAt)}',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9098B1)),
                    ),
                  ],

                  if (p.catatan != null && p.catatan!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.catatan!,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF2D3142)),
                      ),
                    ),
                  ],

                  // Catatan mahasiswa (bukti revisi)
                  if (p.status == 'menunggu_konfirmasi' &&
                      p.catatanMahasiswa != null &&
                      p.catatanMahasiswa!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📝 Bukti revisi mahasiswa:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.catatanMahasiswa!,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF2D3142)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // FITUR 4: Tombol ACC / Revisi oleh dosen
                  if (p.status == 'menunggu_konfirmasi') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _dosenRevisi(ctx, p, mahasiswaId),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(
                                  color: Color(0xFFEF4444)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Revisi Lagi',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _dosenAcc(ctx, p, mahasiswaId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('ACC ✓',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ),
                        ),
                      ],
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

  Future<void> _dosenAcc(
      BuildContext ctx, ProgresModel p, int mahasiswaId) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final success = await context.read<ProgresProvider>().updateStatusByDosen(
        p.id!, 'acc', p.catatan, user.id!);

    if (!ctx.mounted) return;

    if (success) {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p.tahapLabel} berhasil di-ACC!'),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
      // Re-open bottom sheet with updated data (will auto-refresh via provider)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal update. Coba lagi.'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _dosenRevisi(
      BuildContext ctx, ProgresModel p, int mahasiswaId) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final TextEditingController catatanCtrl = TextEditingController();
    final primaryColor = Theme.of(context).primaryColor;
    bool isSubmitting = false;

    await showDialog(
      context: ctx,
      builder: (dialogCtx) {
        return StatefulBuilder(builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Kembalikan untuk Revisi',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tuliskan catatan revisi untuk mahasiswa:',
                    style: TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: catatanCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Catatan revisi...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (catatanCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Harap isi catatan revisi!'),
                                backgroundColor: Colors.orange),
                          );
                          return;
                        }
                        setDialogState(() => isSubmitting = true);

                        final success = await context
                            .read<ProgresProvider>()
                            .updateStatusByDosen(
                                p.id!,
                                'revisi',
                                catatanCtrl.text.trim(),
                                user.id!);

                        if (!dialogCtx.mounted) return;
                        Navigator.pop(dialogCtx);

                        if (success) {
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx); // close bottom sheet
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${p.tahapLabel} dikembalikan untuk revisi.'),
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                ),
                child: const Text('Kirim Revisi',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final progresProvider = context.watch<ProgresProvider>();
    final targetProvider = context.watch<TargetProvider>();
    final user = auth.currentUser;
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final grouped = progresProvider.tahapGroupedByMahasiswa;
    final mahasiswaIds = grouped.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Daftar Mahasiswa Bimbingan',
              style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
            ),
            if (progresProvider.menungguKonfirmasiCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${progresProvider.menungguKonfirmasiCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF9098B1)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: progresProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : mahasiswaIds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada mahasiswa bimbingan.',
                        style: TextStyle(color: textGrey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20.0),
                    itemCount: mahasiswaIds.length,
                    itemBuilder: (context, index) {
                      final mahasiswaId = mahasiswaIds[index];
                      final tahapList = grouped[mahasiswaId]!;
                      final namaMahasiswa =
                          tahapList.isNotEmpty ? tahapList.first.namaMahasiswa ?? 'Mahasiswa' : 'Mahasiswa';
                      final judulSkripsi = tahapList.isNotEmpty
                          ? tahapList.first.judulSkripsi
                          : '-';

                      final accCount = tahapList.where((p) => p.status == 'acc').length;
                      final total = tahapList.length;
                      final pct = total > 0 ? accCount / total : 0.0;

                      final hasMenunggu = tahapList
                          .any((p) => p.status == 'menunggu_konfirmasi');
                      final menungguCount = tahapList
                          .where((p) => p.status == 'menunggu_konfirmasi')
                          .length;

                      // Target
                      final targetData = targetProvider.allTargets
                          .where((t) => t['mahasiswa_id'] == mahasiswaId)
                          .firstOrNull;
                      final targetSelesai =
                          targetData?['target_selesai'] as String?;
                      final sisaHari = targetSelesai != null
                          ? TargetProvider.hitungSisaHari(targetSelesai)
                          : null;
                      final warnaTarget = sisaHari != null
                          ? TargetProvider.warnaIndikator(sisaHari)
                          : Colors.grey;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: hasMenunggu
                              ? Border.all(
                                  color: const Color(0xFFF59E0B),
                                  width: 1.5)
                              : null,
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
                            // Header
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      primaryColor.withValues(alpha: 0.1),
                                  child: Text(
                                    namaMahasiswa.isNotEmpty
                                        ? namaMahasiswa[0]
                                        : 'M',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        namaMahasiswa,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: textDark,
                                        ),
                                      ),
                                      Text(
                                        tahapList.isNotEmpty &&
                                                tahapList.first.namaMahasiswa != null
                                            ? 'ID: $mahasiswaId'
                                            : 'ID: $mahasiswaId',
                                        style: const TextStyle(
                                            fontSize: 11, color: textGrey),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasMenunggu)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$menungguCount menunggu',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Judul Skripsi
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: Colors.grey.shade100),
                              ),
                              child: Text(
                                '"$judulSkripsi"',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: textDark,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Progress bar
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Progres: $accCount/$total tahap ACC',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: textDark),
                                      ),
                                      const SizedBox(height: 6),
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
                                const SizedBox(width: 12),
                                Text(
                                  '${(pct * 100).toInt()}%',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor),
                                ),
                              ],
                            ),

                            // Target Selesai — FITUR 2 di sisi dosen
                            if (targetSelesai != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: warnaTarget.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color:
                                          warnaTarget.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.flag_outlined,
                                        color: warnaTarget, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Target: ${DateFormat('dd MMM yyyy').format(DateTime.parse(targetSelesai))} • ${sisaHari! < 0 ? 'Lewat ${sisaHari.abs()} hari' : 'Sisa $sisaHari hari'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: warnaTarget,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Action button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showProgressBottomSheet(
                                    context,
                                    mahasiswaId,
                                    namaMahasiswa,
                                    tahapList),
                                icon: Icon(Icons.analytics_outlined,
                                    size: 16, color: primaryColor),
                                label: Text(
                                  hasMenunggu
                                      ? 'Lihat Progres ($menungguCount Perlu Konfirmasi)'
                                      : 'Lihat Progres Skripsi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: hasMenunggu
                                        ? const Color(0xFFF59E0B)
                                        : primaryColor,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: hasMenunggu
                                        ? const Color(0xFFF59E0B)
                                        : primaryColor.withValues(alpha: 0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }
}
