import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progres_provider.dart';
import '../../providers/target_provider.dart';
import '../../database/supabase_service.dart';
import '../../models/user_model.dart';
import '../../models/booking_model.dart';

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
      context.read<TargetProvider>().fetchAllTargetByDosen(user.id!),
    ]);
  }

  /// Tampilkan bottom sheet detail mahasiswa (Profil & Booking)
  void _showProgressBottomSheet(
    BuildContext context,
    int mahasiswaId,
    String namaMahasiswa,
  ) {
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DefaultTabController(
          length: 2,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detail: $namaMahasiswa',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
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
                TabBar(
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: primaryColor,
                  tabs: const [
                    Tab(text: 'Riwayat Booking'),
                    Tab(text: 'Profil'),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: BOOKING
                      FutureBuilder<List<BookingModel>>(
                        future: SupabaseService().getBookingByMahasiswa(
                          mahasiswaId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('Belum ada riwayat booking.'),
                            );
                          }
                          final bookings = snapshot.data!;
                          return ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              final b = bookings[index];
                              Color statusColor = Colors.grey;
                              if (b.status == 'approved') {
                                statusColor = Colors.green;
                              }
                              if (b.status == 'rejected') {
                                statusColor = Colors.red;
                              }
                              if (b.status == 'pending') {
                                statusColor = Colors.orange;
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Keperluan:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            b.status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(b.keperluan),
                                      if (b.catatanStaf != null &&
                                          b.catatanStaf!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Catatan: ${b.catatanStaf}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      // TAB 2: PROFIL
                      FutureBuilder<UserModel?>(
                        future: SupabaseService().getUserById(mahasiswaId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final u = snapshot.data;
                          if (u == null) {
                            return const Center(
                              child: Text('Gagal memuat profil'),
                            );
                          }

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Text(
                                    u.nama.isNotEmpty
                                        ? u.nama[0].toUpperCase()
                                        : 'M',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  u.nama,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  u.nimNip,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 24),
                                ListTile(
                                  leading: const Icon(Icons.email),
                                  title: const Text('Email'),
                                  subtitle: Text(u.email),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.school),
                                  title: const Text('Jurusan'),
                                  subtitle: Text(u.jurusan),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final grouped = progresProvider.tahapGroupedByMahasiswa;
    final mahasiswaIds = grouped.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Daftar Mahasiswa Bimbingan',
          style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
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
                  Icon(
                    Icons.people_outline_rounded,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
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
                  final namaMahasiswa = tahapList.isNotEmpty
                      ? tahapList.first.namaMahasiswa ?? 'Mahasiswa'
                      : 'Mahasiswa';
                  final judulSkripsi = tahapList.isNotEmpty
                      ? tahapList.first.judulSkripsi
                      : '-';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: primaryColor.withValues(
                                alpha: 0.1,
                              ),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    'ID: $mahasiswaId',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: textGrey,
                                    ),
                                  ),
                                ],
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
                            border: Border.all(color: Colors.grey.shade100),
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

                        // Action button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showProgressBottomSheet(
                              context,
                              mahasiswaId,
                              namaMahasiswa,
                            ),
                            icon: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: primaryColor,
                            ),
                            label: Text(
                              'Lihat Detail & Riwayat',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: primaryColor.withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
}
