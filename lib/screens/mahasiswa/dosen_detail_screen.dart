import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../database/supabase_service.dart';
import '../../models/user_model.dart';
import '../../models/jadwal_model.dart';
import '../../models/booking_model.dart';

/// Halaman detail dosen yang menampilkan profil lengkap dan jadwal tersedia.
/// Mahasiswa hanya dapat booking jika dosen ini adalah pembimbingnya.
class DosenDetailScreen extends StatefulWidget {
  final UserModel dosen;
  final bool isPembimbing; // Apakah ini dosen pembimbing mahasiswa?

  const DosenDetailScreen({
    super.key,
    required this.dosen,
    required this.isPembimbing,
  });

  @override
  State<DosenDetailScreen> createState() => _DosenDetailScreenState();
}

class _DosenDetailScreenState extends State<DosenDetailScreen> {
  List<JadwalModel> _jadwalTersedia = [];
  bool _isLoadingJadwal = true;
  final TextEditingController _keperluanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadJadwal();
  }

  @override
  void dispose() {
    _keperluanController.dispose();
    super.dispose();
  }

  /// Memuat jadwal tersedia dari dosen ini
  Future<void> _loadJadwal() async {
    if (mounted) setState(() => _isLoadingJadwal = true);
    try {
      final jadwal = await SupabaseService().getJadwalTersedia(widget.dosen.id!);
      if (mounted) setState(() => _jadwalTersedia = jadwal);
    } catch (e) {
      // silently fail
    } finally {
      if (mounted) setState(() => _isLoadingJadwal = false);
    }
  }

  /// Dialog booking jadwal
  void _showBookingDialog(JadwalModel jadwal) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    _keperluanController.clear();

    final primaryColor = Theme.of(context).primaryColor;

    // Jika bukan pembimbing, tampilkan dialog peringatan
    if (!widget.isPembimbing) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Booking Tidak Diizinkan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: const Text(
            'Dosen yang Anda pilih bukan merupakan dosen pembimbing Anda.\n\n'
            'Silakan hubungi staf akademik untuk mengatur dosen pembimbing Anda.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Mengerti', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.event_available, color: primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Buat Booking Bimbingan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info jadwal yang dipilih
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.person, widget.dosen.nama),
                        const SizedBox(height: 6),
                        _infoRow(Icons.calendar_month, '${jadwal.hari}, ${jadwal.tanggal}'),
                        const SizedBox(height: 4),
                        _infoRow(Icons.access_time, '${jadwal.jamMulai} - ${jadwal.jamSelesai}'),
                        const SizedBox(height: 4),
                        _infoRow(Icons.location_on, jadwal.lokasi),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Keperluan Bimbingan:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keperluanController,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Konsultasi BAB 2, Perbaikan metodologi...',
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (_keperluanController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Keperluan bimbingan harus diisi!'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);

                        final booking = BookingModel(
                          mahasiswaId: user.id!,
                          dosenId: widget.dosen.id!,
                          jadwalId: jadwal.id!,
                          tanggal: jadwal.tanggal,
                          keperluan: _keperluanController.text.trim(),
                          status: 'pending',
                          createdAt: DateTime.now().toIso8601String(),
                        );

                        final errorMsg = await context
                            .read<BookingProvider>()
                            .createBooking(booking);

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;

                        if (errorMsg == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                      child: Text(
                                          'Booking berhasil! Menunggu persetujuan dosen.')),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          _loadJadwal(); // refresh jadwal
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(errorMsg),
                                backgroundColor: Colors.red),
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
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Booking',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);
    final dosen = widget.dosen;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Detail Dosen',
          style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: primaryColor),
            onPressed: _loadJadwal,
            tooltip: 'Refresh jadwal',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== KARTU PROFIL DOSEN =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // Foto profil
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.1),
                      border: Border.all(color: primaryColor.withOpacity(0.3), width: 3),
                    ),
                    child: ClipOval(
                      child: dosen.foto != null && dosen.foto!.startsWith('http')
                          ? Image.network(dosen.foto!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildInitialAvatar(dosen.nama, primaryColor, 36))
                          : _buildInitialAvatar(dosen.nama, primaryColor, 36),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nama
                  Text(
                    dosen.nama,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Badge pembimbing
                  if (widget.isPembimbing)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            'Dosen Pembimbing Saya',
                            style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Info detail
                  _buildDetailRow(Icons.badge_outlined, 'NIDN',
                      dosen.nidn ?? '-', primaryColor),
                  const Divider(height: 20),
                  _buildDetailRow(Icons.email_outlined, 'Email',
                      dosen.email, primaryColor),
                  const Divider(height: 20),
                  _buildDetailRow(Icons.school_outlined, 'Program Studi',
                      dosen.prodi ?? dosen.jurusan, primaryColor),
                  const Divider(height: 20),
                  _buildDetailRow(Icons.lightbulb_outlined, 'Bidang Keahlian',
                      dosen.bidangKeahlian ?? '-', primaryColor),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ===== JADWAL TERSEDIA =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jadwal Tersedia',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark),
                ),
                if (!widget.isPembimbing)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Hanya untuk pembimbing',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoadingJadwal)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator()))
            else if (_jadwalTersedia.isEmpty)
              _buildEmptyJadwal()
            else
              ..._jadwalTersedia.map((j) => _buildJadwalCard(j, primaryColor)),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(String nama, Color primaryColor, double fontSize) {
    return Container(
      color: primaryColor.withOpacity(0.1),
      child: Center(
        child: Text(
          nama.isNotEmpty ? nama[0].toUpperCase() : 'D',
          style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: primaryColor),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, Color primaryColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9098B1))),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3142))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyJadwal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Belum Ada Jadwal Tersedia',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          const SizedBox(height: 6),
          const Text(
            'Dosen ini belum membuat jadwal bimbingan atau semua sudah penuh.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalCard(JadwalModel jadwal, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.event_available,
                      color: Colors.green, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${jadwal.hari}, ${_formatTanggal(jadwal.tanggal)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF2D3142))),
                      Text('${jadwal.jamMulai} - ${jadwal.jamSelesai}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Tersedia',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(jadwal.lokasi,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey))),
              ],
            ),
            if (jadwal.keterangan != null && jadwal.keterangan!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(jadwal.keterangan!,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey))),
                ],
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showBookingDialog(jadwal),
                icon: Icon(
                  widget.isPembimbing
                      ? Icons.add_circle_outline
                      : Icons.lock_outline,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  widget.isPembimbing
                      ? 'Booking Jadwal Ini'
                      : 'Hanya untuk Mahasiswa Bimbingan',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isPembimbing
                      ? primaryColor
                      : Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTanggal(String tanggal) {
    try {
      return DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.parse(tanggal));
    } catch (_) {
      return tanggal;
    }
  }
}
