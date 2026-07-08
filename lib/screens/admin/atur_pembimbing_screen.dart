import 'package:flutter/material.dart';
import '../../database/supabase_service.dart';
import '../../models/user_model.dart';

/// Halaman untuk Staff menentukan atau mengubah dosen pembimbing mahasiswa.
/// Alur: Pilih Mahasiswa → Pilih Dosen → Simpan ke Supabase
class AturPembimbingScreen extends StatefulWidget {
  const AturPembimbingScreen({super.key});

  @override
  State<AturPembimbingScreen> createState() => _AturPembimbingScreenState();
}

class _AturPembimbingScreenState extends State<AturPembimbingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data untuk tab "Atur Baru"
  List<UserModel> _mahasiswaList = [];
  List<UserModel> _dosenList = [];
  UserModel? _selectedMahasiswa;
  UserModel? _selectedDosen;
  bool _isLoadingSetup = true;
  bool _isSubmitting = false;

  // Data untuk tab "Daftar Relasi"
  List<Map<String, dynamic>> _relasiList = [];
  bool _isLoadingRelasi = true;

  final SupabaseService _service = SupabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Memuat data mahasiswa, dosen, dan relasi yang sudah ada
  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoadingSetup = true;
        _isLoadingRelasi = true;
      });
    }

    try {
      // Load paralel
      final results = await Future.wait([
        _service.getAllMahasiswa(),
        _service.getAllDosen(),
        _service.getAllDosenPembimbingRelasi(),
      ]);

      if (mounted) {
        setState(() {
          _mahasiswaList = results[0] as List<UserModel>;
          _dosenList = results[1] as List<UserModel>;
          _relasiList = results[2] as List<Map<String, dynamic>>;
          _isLoadingSetup = false;
          _isLoadingRelasi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSetup = false;
          _isLoadingRelasi = false;
        });
      }
    }
  }

  /// Menyimpan relasi dosen pembimbing ke Supabase
  Future<void> _savePembimbing() async {
    if (_selectedMahasiswa == null || _selectedDosen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih mahasiswa dan dosen terlebih dahulu!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await _service.setDosenPembimbing(
      _selectedMahasiswa!.id!,
      _selectedDosen!.id!,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (success) {
          _selectedMahasiswa = null;
          _selectedDosen = null;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Dosen pembimbing berhasil ditetapkan!'
              : 'Gagal menyimpan. Coba lagi.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadData(); // Refresh relasi list
        _tabController.animateTo(1); // Pindah ke tab daftar relasi
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Atur Dosen Pembimbing',
          style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: primaryColor),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: textGrey,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline, size: 18), text: 'Atur Baru'),
            Tab(icon: Icon(Icons.list_alt_outlined, size: 18), text: 'Daftar Relasi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ===== TAB 1: ATUR PEMBIMBING BARU =====
          _buildAturTab(primaryColor, textDark, textGrey),

          // ===== TAB 2: DAFTAR RELASI =====
          _buildRelasiTab(primaryColor, textDark, textGrey),
        ],
      ),
    );
  }

  Widget _buildAturTab(Color primaryColor, Color textDark, Color textGrey) {
    if (_isLoadingSetup) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Pilih mahasiswa dan dosen, lalu simpan untuk menetapkan atau mengubah dosen pembimbing.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF2D3142)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ===== PILIH MAHASISWA =====
          const Text(
            'Pilih Mahasiswa',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
              ],
            ),
            child: DropdownButtonFormField<UserModel>(
              value: _selectedMahasiswa,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.person_outline),
                hintText: 'Pilih mahasiswa...',
              ),
              items: _mahasiswaList
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text('${m.nama} (${m.nimNip})',
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedMahasiswa = val),
            ),
          ),
          const SizedBox(height: 12),

          // Panah
          Center(
            child: Icon(Icons.arrow_downward_rounded,
                color: primaryColor, size: 28),
          ),
          const SizedBox(height: 12),

          // ===== PILIH DOSEN =====
          const Text(
            'Pilih Dosen Pembimbing',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
              ],
            ),
            child: DropdownButtonFormField<UserModel>(
              value: _selectedDosen,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.school_outlined),
                hintText: 'Pilih dosen...',
              ),
              items: _dosenList
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(
                          '${d.nama}${d.nidn != null ? " (${d.nidn})" : ""}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedDosen = val),
            ),
          ),
          const SizedBox(height: 28),

          // Preview pilihan
          if (_selectedMahasiswa != null && _selectedDosen != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ringkasan Penetapan:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(_selectedMahasiswa!.nama,
                        style: const TextStyle(fontSize: 13)),
                  ]),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.arrow_downward, size: 16, color: Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.school, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(_selectedDosen!.nama,
                        style: const TextStyle(fontSize: 13)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Tombol simpan
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _savePembimbing,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                _isSubmitting ? 'Menyimpan...' : 'Simpan Penetapan',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelasiTab(Color primaryColor, Color textDark, Color textGrey) {
    if (_isLoadingRelasi) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_relasiList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Belum ada relasi dosen pembimbing.',
                style: TextStyle(color: Color(0xFF9098B1), fontSize: 14)),
            const SizedBox(height: 8),
            const Text('Gunakan tab "Atur Baru" untuk menetapkan.',
                style: TextStyle(color: Color(0xFF9098B1), fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _relasiList.length,
        itemBuilder: (context, index) {
          final item = _relasiList[index];
          final mahasiswaData = item['mahasiswa'];
          final dosenData = item['dosen'];

          final namaMahasiswa = mahasiswaData?['nama'] ?? 'Mahasiswa';
          final nimMahasiswa = mahasiswaData?['nim_nip'] ?? '-';
          final namaDosen = dosenData?['nama'] ?? 'Dosen';
          final nidnDosen = dosenData?['nidn'] ?? '-';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                // Mahasiswa icon
                CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Text(
                    namaMahasiswa.isNotEmpty ? namaMahasiswa[0] : 'M',
                    style: TextStyle(
                        color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(namaMahasiswa,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF2D3142))),
                      Text('NIM: $nimMahasiswa',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9098B1))),
                      const SizedBox(height: 4),
                      // Panah → dosen
                      Row(
                        children: [
                          const Icon(Icons.arrow_forward_rounded,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              namaDosen,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text('NIDN: $nidnDosen',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9098B1))),
                    ],
                  ),
                ),
                // Tombol ubah
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: primaryColor, size: 20),
                  onPressed: () {
                    // Pre-select mahasiswa dan dosen, lalu pindah ke tab atur baru
                    final mahasiswaObj = _mahasiswaList.firstWhere(
                      (m) => m.id == item['mahasiswa_id'],
                      orElse: () => _mahasiswaList.first,
                    );
                    final dosenObj = _dosenList.firstWhere(
                      (d) => d.id == item['dosen_id'],
                      orElse: () => _dosenList.first,
                    );
                    setState(() {
                      _selectedMahasiswa = mahasiswaObj;
                      _selectedDosen = dosenObj;
                    });
                    _tabController.animateTo(0);
                  },
                  tooltip: 'Ubah Pembimbing',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
