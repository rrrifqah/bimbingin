import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progres_provider.dart';
import '../../providers/target_provider.dart';
import '../../models/progres_model.dart';
import 'mahasiswa_main.dart';
import '../../database/supabase_service.dart';
import '../../models/user_model.dart';

class MahasiswaDashboard extends StatefulWidget {
  const MahasiswaDashboard({super.key});

  @override
  State<MahasiswaDashboard> createState() => _MahasiswaDashboardState();
}

class _MahasiswaDashboardState extends State<MahasiswaDashboard> {
  bool _dataLoaded = false;
  UserModel? _dosenPembimbing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      _dataLoaded = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    await Future.wait([
      context.read<ProgresProvider>().fetchTahapMahasiswa(user.id!),
      context.read<TargetProvider>().fetchTargetMahasiswa(user.id!),
    ]);

    final supabase = SupabaseService();
    final dosenId = await supabase.getDosenPembimbingByMahasiswa(user.id!);
    if (dosenId != null) {
      final dosen = await supabase.getUserById(dosenId);
      if (mounted) {
        setState(() {
          _dosenPembimbing = dosen;
        });
      }
    }
  }

  Future<void> _selectTargetDate(BuildContext context) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final targetProvider = context.read<TargetProvider>();
    DateTime initialDate = DateTime.now().add(const Duration(days: 60));
    final existingTarget = targetProvider.targetMahasiswa?['target_selesai'] as String?;
    if (existingTarget != null) {
      try {
        initialDate = DateTime.parse(existingTarget);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(DateTime.now()) ? initialDate : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'Pilih Target Selesai Skripsi',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF2D3142),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final targetStr =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      
      final success = await targetProvider.upsertTarget(user.id!, targetStr, user.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Target selesai berhasil diperbarui!' : 'Gagal memperbarui target.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showProgresBottomSheet(BuildContext context) {
    final tahapList = context.read<ProgresProvider>().tahapMahasiswa;
    final primaryColor = Theme.of(context).primaryColor;

    final accCount = tahapList.where((p) => p.status == 'acc').length;
    final total = tahapList.length;
    final pct = total > 0 ? accCount / total : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
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
              // Handle bar
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
                    const Text(
                      'Timeline Progres Skripsi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Progress bar summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$accCount dari $total Tahap ACC',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        Text(
                          '${(pct * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
                          return _buildTimelineItem(p, isLast, primaryColor);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem(
      ProgresModel p, bool isLast, Color primaryColor) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (p.status) {
      case 'acc':
        statusColor = const Color(0xFF22C55E);
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'ACC';
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
        statusLabel = 'Belum';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(statusIcon, color: statusColor, size: 22),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: p.status == 'acc'
                        ? const Color(0xFF22C55E)
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.25),
                ),
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
                            fontSize: 14,
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
                  if (p.catatan != null && p.catatan!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Catatan dosen: ${p.catatan}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF2D3142)),
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tahapList = progresProvider.tahapMahasiswa;
    final accCount = tahapList.where((p) => p.status == 'acc').length;
    final total = tahapList.length;
    final pct = total > 0 ? accCount / total : 0.0;

    final target = targetProvider.targetMahasiswa;
    final targetSelesai = target?['target_selesai'] as String?;
    final sisaHari =
        targetSelesai != null ? TargetProvider.hitungSisaHari(targetSelesai) : null;

    String targetStatus = 'Dalam Target';
    Color warnaTarget = const Color(0xFF3B4FE4); // Blue
    IconData iconTarget = Icons.alarm_on_rounded;
    
    if (targetSelesai != null) {
      final isCompleted = tahapList.isNotEmpty &&
          tahapList.any((p) => p.tahap == 'selesai' && p.status == 'acc');
      if (isCompleted) {
        final selesaiStage = tahapList.firstWhere((p) => p.tahap == 'selesai' && p.status == 'acc');
        try {
          final completionDate = DateTime.parse(selesaiStage.updatedAt);
          final targetDate = DateTime.parse(targetSelesai);
          final compDay = DateTime(completionDate.year, completionDate.month, completionDate.day);
          final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
          if (compDay.isBefore(targetDay) || compDay.isAtSameMomentAs(targetDay)) {
            targetStatus = 'Selesai Tepat Waktu';
            warnaTarget = const Color(0xFF22C55E); // Green
            iconTarget = Icons.check_circle_rounded;
          } else {
            targetStatus = 'Target Terlewati';
            warnaTarget = const Color(0xFFEF4444); // Red
            iconTarget = Icons.error_outline_rounded;
          }
        } catch (_) {
          targetStatus = 'Selesai Tepat Waktu';
          warnaTarget = const Color(0xFF22C55E);
          iconTarget = Icons.check_circle_rounded;
        }
      } else {
        if (sisaHari != null && sisaHari < 0) {
          targetStatus = 'Target Terlewati';
          warnaTarget = const Color(0xFFEF4444); // Red
          iconTarget = Icons.error_outline_rounded;
        } else {
          targetStatus = 'Dalam Target';
          warnaTarget = const Color(0xFF3B4FE4); // Blue
          iconTarget = Icons.alarm_on_rounded;
        }
      }
    }

    // Judul skripsi dari tahap pertama
    final judulSkripsi = tahapList.isNotEmpty ? tahapList.first.judulSkripsi : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProgresBottomSheet(context),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.analytics_rounded, color: Colors.white),
        label: const Text(
          'Lihat Progres',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                            'NIM: ${user.nimNip} | ${user.jurusan}',
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

                // Title of thesis card
                if (judulSkripsi.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.2),
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
                            Icon(Icons.menu_book_rounded,
                                color: Colors.white, size: 20),
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
                          '"$judulSkripsi"',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Dosen Pembimbing Card
                const Text(
                  'Dosen Pembimbing',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: _dosenPembimbing == null
                      ? Row(
                          children: [
                            const Icon(Icons.person_off_outlined, color: textGrey),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Belum memiliki Dosen Pembimbing',
                                style: TextStyle(color: textGrey, fontSize: 13),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: primaryColor.withOpacity(0.1),
                              child: Text(
                                _dosenPembimbing!.nama.isNotEmpty ? _dosenPembimbing!.nama[0].toUpperCase() : 'D',
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _dosenPembimbing!.nama,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'NIP: ${_dosenPembimbing!.nimNip}',
                                    style: const TextStyle(color: textGrey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 24),

                // Target Waktu Selesai Card — FITUR 2
                const Text(
                  'Target Waktu Selesai',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark),
                ),
                const SizedBox(height: 12),
                targetProvider.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ))
                    : targetSelesai == null
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.hourglass_empty_rounded,
                                    color: Color(0xFF9098B1)),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Belum ada target yang ditetapkan',
                                    style: TextStyle(
                                        color: Color(0xFF9098B1),
                                        fontSize: 13),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _selectTargetDate(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Atur Target',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: targetStatus == 'Target Terlewati' ? const Color(0xFFFEF2F2) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: targetStatus == 'Target Terlewati' ? const Color(0xFFFCA5A5) : warnaTarget.withValues(alpha: 0.3),
                                width: targetStatus == 'Target Terlewati' ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: warnaTarget.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: warnaTarget.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    iconTarget,
                                    color: warnaTarget,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Target: ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.parse(targetSelesai))}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: targetStatus == 'Target Terlewati' ? const Color(0xFF991B1B) : textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        targetStatus == 'Target Terlewati'
                                            ? 'Target sudah terlewati!'
                                            : targetStatus == 'Selesai Tepat Waktu'
                                                ? 'Selesai Tepat Waktu!'
                                                : 'Sisa $sisaHari hari lagi',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: warnaTarget,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: warnaTarget.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        targetStatus.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: warnaTarget,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    IconButton(
                                      icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                                      color: const Color(0xFF9098B1),
                                      onPressed: () => _selectTargetDate(context),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Ubah Target',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                const SizedBox(height: 24),

                // Progres summary
                const Text(
                  'Progres Bimbingan Bab',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: progresProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$accCount dari $total Tahap Selesai (ACC)',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textDark),
                                ),
                                Text(
                                  '${(pct * 100).toInt()}%',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade100,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Dot indicators
                            if (tahapList.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tahapList.map((p) {
                                  Color dotColor;
                                  switch (p.status) {
                                    case 'acc':
                                      dotColor = const Color(0xFF22C55E);
                                      break;
                                    case 'revisi':
                                      dotColor = const Color(0xFFEF4444);
                                      break;
                                    case 'menunggu_konfirmasi':
                                      dotColor = const Color(0xFFF59E0B);
                                      break;
                                    default:
                                      dotColor = Colors.grey.shade400;
                                  }
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: dotColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        p.tahapLabel.split(':')[0],
                                        style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: textDark),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 8),
                            // Legend
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _buildLegend(
                                    const Color(0xFF22C55E), 'ACC'),
                                _buildLegend(
                                    const Color(0xFFF59E0B), 'Menunggu'),
                                _buildLegend(
                                    const Color(0xFFEF4444), 'Revisi'),
                                _buildLegend(
                                    Colors.grey.shade400, 'Belum'),
                              ],
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 24),

                // Notifikasi: tahap dengan status 'revisi'
                if (tahapList.any((p) => p.status == 'revisi')) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ada Tahap yang Perlu Direvisi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Buka halaman Progres untuk upload bukti revisi.',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2D3142)),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final rootState =
                                context.findAncestorStateOfType<
                                    MahasiswaMainState>();
                            if (rootState != null) rootState.setIndex(2);
                          },
                          child: const Text('Buka',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Quick action to booking
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text(
                        'Booking jadwal bimbingan baru?',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9098B1),
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final rootState =
                              context.findAncestorStateOfType<
                                  MahasiswaMainState>();
                          if (rootState != null) rootState.setIndex(1);
                        },
                        icon: const Icon(Icons.add_rounded,
                            size: 18, color: Colors.white),
                        label: const Text('Buat Booking Baru',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // space for FAB
              ],
            ),
          ),
        ),
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
            style: const TextStyle(fontSize: 9, color: Color(0xFF9098B1))),
      ],
    );
  }
}
