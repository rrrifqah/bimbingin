import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../database/supabase_service.dart';
import '../../models/user_model.dart';
import 'dosen_detail_screen.dart';

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

      // Load paralel: daftar dosen dan dosen pembimbing
      final results = await Future.wait([
        supabase.getAllDosenWithScheduleStatus(),
        supabase.getDosenPembimbingByMahasiswa(user.id!),
      ]);

      final dosenList = results[0] as List<Map<String, dynamic>>;
      final dosenPembimbingId = results[1] as int?;

      if (mounted) {
        setState(() {
          _allDosen = dosenList;
          _dosenPembimbingId = dosenPembimbingId;
          _filteredDosen = dosenList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Filter dosen berdasarkan query pencarian
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredDosen = _allDosen;
      } else {
        _filteredDosen = _allDosen.where((d) {
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
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris nama + icon logout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${user.nama.split(' ').first} 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Temukan dosen dan jadwal bimbingan',
                              style: const TextStyle(
                                  fontSize: 13, color: textGrey),
                            ),
                          ],
                        ),
                      ),
                      // Tombol refresh
                      IconButton(
                        onPressed: _loadData,
                        icon: Icon(Icons.refresh_rounded, color: primaryColor),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ===== SEARCH BAR =====
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Cari dosen, NIDN, prodi, atau bidang keahlian...',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: textGrey),
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
                      fillColor: const Color(0xFFF4F7FB),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
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
                                  _filteredDosen[index], primaryColor);
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
                color: Color(0xFF9098B1)),
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
            ? Border.all(color: primaryColor.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 12, color: primaryColor),
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
                            Icons.badge_outlined, 'NIDN: ${dosen.nidn}'),

                      // Program Studi
                      if (dosen.prodi != null && dosen.prodi!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _buildInfoChip(Icons.school_outlined, dosen.prodi!),
                      ] else ...[
                        const SizedBox(height: 3),
                        _buildInfoChip(Icons.school_outlined, dosen.jurusan),
                      ],

                      // Bidang Keahlian
                      if (dosen.bidangKeahlian != null && dosen.bidangKeahlian!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _buildInfoChip(
                            Icons.lightbulb_outlined, dosen.bidangKeahlian!),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: hasJadwal
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
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
                  icon: const Icon(Icons.info_outline, size: 15, color: Colors.white),
                  label: const Text(
                    'Lihat Detail',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
        color: primaryColor.withOpacity(0.1),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
      ),
      child: ClipOval(
        child: dosen.foto != null && dosen.foto!.startsWith('http')
            ? Image.network(
                dosen.foto!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
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
}
