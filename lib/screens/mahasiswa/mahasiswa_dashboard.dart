import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../database/supabase_service.dart';
import '../../models/user_model.dart';
import '../../models/booking_model.dart';
import 'dosen_detail_screen.dart';
import 'mahasiswa_main.dart';
import '../auth/login_screen.dart';

/// Dashboard Mahasiswa — menampilkan daftar semua dosen yang dapat di-browse.
/// Mahasiswa dapat mencari dosen, melihat detail, dan booking (jika pembimbing).
class MahasiswaDashboard extends StatefulWidget {
  const MahasiswaDashboard({super.key});

  @override
  State<MahasiswaDashboard> createState() => _MahasiswaDashboardState();
}

class _MahasiswaDashboardState extends State<MahasiswaDashboard> {
  // State untuk daftar dosen dan pencarian
  List<Map<String, dynamic>> _allDosen = [];
  List<Map<String, dynamic>> _filteredDosen = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int? _dosenPembimbingId; // ID dosen pembimbing mahasiswa

  // State untuk booking aktif
  BookingModel? _activeBooking;
  int? _activeBookingQueue;
  String? _activeBookingTimeSlot;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load data setelah frame pertama render (agar context tersedia)
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Memuat daftar dosen dan info dosen pembimbing mahasiswa
  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final supabase = SupabaseService();

      // Load paralel: daftar dosen, dosen pembimbing, dan booking aktif
      final results = await Future.wait([
        supabase.getAllDosenWithScheduleStatus(),
        supabase.getDosenPembimbingByMahasiswa(user.id!),
        supabase.getActiveBookingForMahasiswa(user.id!),
      ]);

      final dosenList = results[0] as List<Map<String, dynamic>>;
      final dosenPembimbingId = results[1] as int?;
      final activeBooking = results[2] as BookingModel?;

      int? queueNum;
      String? timeSlot;

      if (activeBooking != null) {
        // Ambil info antrean dan slot waktu
        final activeList = await supabase.getBookingByJadwalActive(
          activeBooking.jadwalId,
        );
        final index = activeList.indexWhere((b) => b.id == activeBooking.id);
        if (index != -1) {
          queueNum = index + 1;
          timeSlot = _calculateJamBimbingan(
            activeBooking.jamMulai ?? '',
            index,
          );
        }
      }

      if (mounted) {
        setState(() {
          _allDosen = dosenList;
          _dosenPembimbingId = dosenPembimbingId;
          _activeBooking = activeBooking;
          _activeBookingQueue = queueNum;
          _activeBookingTimeSlot = timeSlot;
          _isLoading = false;
          _onSearchChanged(_searchQuery); // Update filtered list
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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

  /// Filter dosen berdasarkan query pencarian
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      // Filter out the booked lecturer from the list below so they are not displayed twice
      final baseList = _allDosen
          .where((d) => d['id'] != _activeBooking?.dosenId)
          .toList();
      if (_searchQuery.isEmpty) {
        _filteredDosen = baseList;
      } else {
        _filteredDosen = baseList.where((d) {
          final nama = (d['nama'] ?? '').toString().toLowerCase();
          final nidn = (d['nidn'] ?? '').toString().toLowerCase();
          final prodi = (d['prodi'] ?? '').toString().toLowerCase();
          final bidang = (d['bidang_keahlian'] ?? '').toString().toLowerCase();
          return nama.contains(_searchQuery) ||
              nidn.contains(_searchQuery) ||
              prodi.contains(_searchQuery) ||
              bidang.contains(_searchQuery);
        }).toList();
      }
    });
  }

  void _openActiveDosenDetail() {
    if (_activeBooking == null) return;
    final dosenMap = _allDosen.firstWhere(
      (d) => d['id'] == _activeBooking!.dosenId,
      orElse: () => {},
    );
    if (dosenMap.isNotEmpty) {
      _openDosenDetail(dosenMap);
    }
  }

  /// Buka halaman detail dosen
  void _openDosenDetail(Map<String, dynamic> dosenData) {
    final dosenModel = UserModel.fromMap(dosenData);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DosenDetailScreen(
          dosen: dosenModel,
          isPembimbing: _dosenPembimbingId == dosenModel.id,
        ),
      ),
    ).then((_) => _loadData()); // Refresh setelah kembali dari detail
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final primaryColor = Theme.of(context).primaryColor;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            _buildHeader(context, user, primaryColor),

            // ===== SEARCH BAR =====
            _buildSearchBar(primaryColor),

            // ===== REMINDER CARD (DI BAWAH SEARCH BAR) =====
            if (_activeBooking != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _buildReminderCard(primaryColor),
              ),

            // ===== HASIL / DAFTAR DOSEN =====
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredDosen.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredDosen.length,
                        itemBuilder: (context, index) {
                          return _buildDosenCard(
                            _filteredDosen[index],
                            primaryColor,
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

  /// Widget empty state saat tidak ada dosen ditemukan
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Belum ada data dosen.'
                : 'Dosen "$_searchQuery" tidak ditemukan.',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9098B1),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Card dosen dalam ListView
  Widget _buildDosenCard(Map<String, dynamic> data, Color primaryColor) {
    final dosen = UserModel.fromMap(data);
    final hasJadwal = data['has_jadwal'] as bool? ?? false;
    final isPembimbing = _dosenPembimbingId == dosen.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isPembimbing
            ? Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== FOTO PROFIL =====
                _buildAvatar(dosen, primaryColor),
                const SizedBox(width: 14),

                // ===== INFO DOSEN =====
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge "Pembimbing Saya" jika ini dosen pembimbing
                      if (isPembimbing) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 12,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pembimbing Saya',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Nama dosen
                      Text(
                        dosen.nama,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // NIDN
                      if (dosen.nidn != null && dosen.nidn!.isNotEmpty)
                        _buildInfoChip(
                          Icons.badge_outlined,
                          'NIDN: ${dosen.nidn}',
                        ),

                      // Program Studi
                      if (dosen.prodi != null && dosen.prodi!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _buildInfoChip(Icons.school_outlined, dosen.prodi!),
                      ] else ...[
                        const SizedBox(height: 3),
                        _buildInfoChip(Icons.school_outlined, dosen.jurusan),
                      ],

                      // Bidang Keahlian
                      if (dosen.bidangKeahlian != null &&
                          dosen.bidangKeahlian!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _buildInfoChip(
                          Icons.lightbulb_outlined,
                          dosen.bidangKeahlian!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Baris bawah: Status Jadwal + Tombol Lihat Detail
            Row(
              children: [
                // Status jadwal
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: hasJadwal
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasJadwal ? Icons.event_available : Icons.event_busy,
                        size: 13,
                        color: hasJadwal ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        hasJadwal ? 'Jadwal Tersedia' : 'Tidak Ada Jadwal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: hasJadwal ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Tombol Lihat Detail
                ElevatedButton.icon(
                  onPressed: () => _openDosenDetail(data),
                  icon: const Icon(
                    Icons.info_outline,
                    size: 15,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Lihat Detail',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Avatar dosen (foto atau inisial)
  Widget _buildAvatar(UserModel dosen, Color primaryColor) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor.withValues(alpha: 0.1),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: dosen.foto != null && dosen.foto!.startsWith('http')
            ? Image.network(
                dosen.foto!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildInitialAvatar(dosen.nama, primaryColor),
              )
            : _buildInitialAvatar(dosen.nama, primaryColor),
      ),
    );
  }

  /// Avatar inisial nama
  Widget _buildInitialAvatar(String nama, Color primaryColor) {
    return Center(
      child: Text(
        nama.isNotEmpty ? nama[0].toUpperCase() : 'D',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  /// Chip info kecil (ikon + teks)
  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF9098B1)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9098B1)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ===== REMINDER CARD WIDGETS =====

  Widget _buildReminderCard(Color primaryColor) {
    if (_activeBooking == null) return const SizedBox.shrink();

    final b = _activeBooking!;
    const Color greenColor = Color(0xFF22C55E);
    const Color darkGreenColor = Color(0xFF15803D);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [greenColor, darkGreenColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: greenColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openActiveDosenDetail,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card reminder: Status + badge nomor antrean
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Booking Aktif',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Antrean #${_activeBookingQueue ?? "-"}',
                        style: const TextStyle(
                          color: darkGreenColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Baris Info Dosen
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Foto Dosen (lebih besar)
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            b.fotoDosen != null &&
                                b.fotoDosen!.startsWith('http')
                            ? Image.network(
                                b.fotoDosen!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildReminderInitialAvatar(
                                      b.namaDosen ?? '',
                                    ),
                              )
                            : _buildReminderInitialAvatar(b.namaDosen ?? ''),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Detail Dosen & Booking
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.namaDosen ?? 'Dosen Pembimbing',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Tanggal
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white70,
                                size: 13,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _formatReminderDate(b.tanggal, b.createdAt),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Jam
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: Colors.white70,
                                size: 13,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _activeBookingTimeSlot ?? b.jam ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderInitialAvatar(String nama) {
    return Center(
      child: Text(
        nama.isNotEmpty ? nama[0].toUpperCase() : 'D',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _formatReminderDate(String? tanggal, String createdAt) {
    if (tanggal == null || tanggal.isEmpty) {
      try {
        final date = DateTime.parse(createdAt);
        return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
      } catch (_) {
        return '-';
      }
    }
    try {
      final date = DateTime.parse(tanggal);
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return tanggal;
    }
  }

  Widget _buildHeader(
    BuildContext context,
    UserModel user,
    Color primaryColor,
  ) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: user.foto != null && user.foto!.startsWith('http')
                  ? Image.network(
                      user.foto!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildInitialAvatarHeader(user.nama),
                    )
                  : _buildInitialAvatarHeader(user.nama),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nama,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'NIM: ${user.nimNip}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                tooltip: 'Pengaturan',
                onSelected: (val) async {
                  if (val == 'profile') {
                    final parentState = context
                        .findAncestorStateOfType<MahasiswaMainState>();
                    if (parentState != null) {
                      parentState.setIndex(2);
                    }
                  } else if (val == 'logout') {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 18,
                          color: Colors.black87,
                        ),
                        SizedBox(width: 8),
                        Text('Profil Saya', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text(
                          'Keluar',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatarHeader(String nama) {
    return Center(
      child: Text(
        nama.isNotEmpty ? nama[0].toUpperCase() : 'M',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color primaryColor) {
    const Color textGrey = Color(0xFF9098B1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Cari dosen, NIDN, prodi, atau bidang keahlian...',
          hintStyle: const TextStyle(fontSize: 13, color: textGrey),
          prefixIcon: const Icon(Icons.search, color: textGrey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: textGrey, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
      ),
    );
  }
}
