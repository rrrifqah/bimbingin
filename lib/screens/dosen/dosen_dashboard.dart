import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progres_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/jadwal_provider.dart';
import '../../models/user_model.dart';
import 'dosen_main.dart';
import '../auth/login_screen.dart';

class DosenDashboard extends StatefulWidget {
  const DosenDashboard({super.key});

  @override
  State<DosenDashboard> createState() => _DosenDashboardState();
}

class _DosenDashboardState extends State<DosenDashboard> {
  bool _dataLoaded = false;
  RealtimeChannel? _bookingChannel;
  RealtimeChannel? _jadwalChannel;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _setupRealtime();
  }

  @override
  void dispose() {
    _searchController.dispose();
    final client = Supabase.instance.client;
    if (_bookingChannel != null) {
      client.removeChannel(_bookingChannel!);
    }
    if (_jadwalChannel != null) {
      client.removeChannel(_jadwalChannel!);
    }
    super.dispose();
  }

  void _setupRealtime() {
    final client = Supabase.instance.client;

    _bookingChannel = client
        .channel('public-booking-changes-dosen-dashboard')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'booking',
          callback: (payload) {
            if (mounted) {
              _loadData();
            }
          },
        );
    _bookingChannel?.subscribe();

    _jadwalChannel = client
        .channel('public-jadwal-changes-dosen-dashboard')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jadwal_dosen',
          callback: (payload) {
            if (mounted) {
              _loadData();
            }
          },
        );
    _jadwalChannel?.subscribe();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      _dataLoaded = true;
      // Defer _loadData to after the current build frame to avoid
      // 'setState() called during build' error from provider notifyListeners()
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadData();
      });
    }
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await Future.wait([
      context.read<ProgresProvider>().fetchTahapGroupedByMahasiswaForDosen(
        user.id!,
      ),
      context.read<BookingProvider>().fetchBookingByDosen(
        user.id!,
        forceRefresh: true,
      ),
      context.read<JadwalProvider>().fetchJadwalDosen(user.id!),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final progresProvider = context.watch<ProgresProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final jadwalProvider = context.watch<JadwalProvider>();

    final user = auth.currentUser;
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final grouped = progresProvider.tahapGroupedByMahasiswa;
    final totalMahasiswa = grouped.keys.length;

    // Hitung total jadwal dibuka
    final totalJadwal = jadwalProvider.jadwalList.length;

    // Hitung total booking disetujui (approved)
    final listBooking = bookingProvider.bookingList;
    final totalBookingApproved = listBooking
        .where((b) => b.status == 'approved')
        .length;
    final approvedBookings = listBooking
        .where((b) => b.status == 'approved')
        .toList();

    final filteredBookings = approvedBookings.where((b) {
      final name = (b.namaMahasiswa ?? '').toLowerCase();
      final nim = (b.nim ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || nim.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            _buildHeader(context, user, primaryColor),

            // ===== SEARCH BAR =====
            _buildSearchBar(primaryColor),

            // ===== CONTENT =====
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              icon: Icons.people_outline_rounded,
                              iconColor: primaryColor,
                              count: totalMahasiswa.toString(),
                              label: 'Mahasiswa\nBimbingan',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              icon: Icons.calendar_month_outlined,
                              iconColor: const Color(0xFFF59E0B),
                              count: totalJadwal.toString(),
                              label: 'Jadwal\nDibuka',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              icon: Icons.check_circle_outline_rounded,
                              iconColor: const Color(0xFF22C55E),
                              count: totalBookingApproved.toString(),
                              label: 'Bimbingan\nAktif',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Jadwal Bimbingan
                      const Text(
                        'Jadwal Bimbingan Saya',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      jadwalProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : jadwalProvider.jadwalList.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const Text(
                                'Belum ada jadwal yang dibuat.',
                                style: TextStyle(color: textGrey, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: jadwalProvider.jadwalList
                                  .take(3)
                                  .length, // Show up to 3
                              itemBuilder: (context, index) {
                                final jadwal = jadwalProvider.jadwalList[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.calendar_today,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      '${jadwal.hari}, ${jadwal.tanggal}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${jadwal.jamMulai} - ${jadwal.jamSelesai}\nStatus: ${jadwal.status.toUpperCase()}',
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 24),

                      // Bimbingan Mahasiswa Terjadwal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bimbingan Mahasiswa Terjadwal',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              final parentState = context
                                  .findAncestorStateOfType<DosenMainState>();
                              if (parentState != null) {
                                parentState.setIndex(1);
                              }
                            },
                            child: Text(
                              'Kelola Jadwal',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (bookingProvider.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (filteredBookings.isEmpty)
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
                              Icon(
                                Icons.calendar_month_outlined,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Belum ada bimbingan terjadwal.'
                                    : 'Tidak ada mahasiswa bimbingan yang cocok.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: textGrey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = filteredBookings[index];
                            final nama = booking.namaMahasiswa ?? 'Mahasiswa';
                            final nim = booking.nim ?? '-';
                            final tanggal = booking.tanggal ?? '-';
                            final jam = booking.jam ?? '-';

                            // Hitung nomor antrean untuk booking ini pada jadwal yang bersangkutan
                            final bookingsForThisJadwal = approvedBookings
                                .where((b) => b.jadwalId == booking.jadwalId)
                                .toList();
                            // Urutkan berdasarkan waktu pembuatan (created_at) ascending agar urutan FCFS valid
                            bookingsForThisJadwal.sort(
                              (a, b) => a.createdAt.compareTo(b.createdAt),
                            );
                            final antrean =
                                bookingsForThisJadwal.indexWhere(
                                  (b) => b.id == booking.id,
                                ) +
                                1;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.shade100,
                                  width: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: Text(
                                      nama.isNotEmpty ? nama[0] : 'M',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                nama,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: textDark,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: primaryColor.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Antrean #$antrean',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'NIM: $nim',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: textGrey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 12,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              tanggal,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: textDark,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(
                                              Icons.access_time,
                                              size: 12,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              jam,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: textDark,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
            color: Colors.black.withValues(alpha: 0.04),
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF9098B1),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
                  'NIP/NIDN: ${user.nimNip}',
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
                        .findAncestorStateOfType<DosenMainState>();
                    if (parentState != null) {
                      parentState.setIndex(
                        2,
                      ); // DosenMain profile tab index is 2
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
        nama.isNotEmpty ? nama[0].toUpperCase() : 'D',
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari mahasiswa bimbingan...',
          hintStyle: const TextStyle(fontSize: 13, color: textGrey),
          prefixIcon: const Icon(Icons.search, color: textGrey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: textGrey, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
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
