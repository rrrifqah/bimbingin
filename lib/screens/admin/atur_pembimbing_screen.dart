import 'package:flutter/material.dart';
import '../../database/supabase_service.dart';
import '../../models/user_model.dart';

/// Halaman untuk Staff memantau dan mengelola hubungan Dosen Pembimbing - Mahasiswa.
/// Menampilkan daftar dosen beserta mahasiswa bimbingannya.
/// Staff dapat mengubah dosen pembimbing mahasiswa atau menentukan pembimbing baru.
class AturPembimbingScreen extends StatefulWidget {
  const AturPembimbingScreen({super.key});

  @override
  State<AturPembimbingScreen> createState() => _AturPembimbingScreenState();
}

class _AturPembimbingScreenState extends State<AturPembimbingScreen> {
  List<UserModel> _dosenList = [];
  List<UserModel> _allMahasiswaList = [];
  Map<int, List<UserModel>> _dosenMahasiswaMap = {};
  bool _isLoading = true;

  final SupabaseService _service = SupabaseService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Memuat data dosen, mahasiswa, dan relasi pembimbing secara realtime
  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _service.getAllDosen(),
        _service.getAllMahasiswa(),
        _service.getAllDosenPembimbingRelasi(),
      ]);

      final dosenList = results[0] as List<UserModel>;
      final mahasiswaList = results[1] as List<UserModel>;
      final relasiList = results[2] as List<Map<String, dynamic>>;

      // Buat pemetaan dosen -> daftar mahasiswa bimbingan
      final map = <int, List<UserModel>>{};
      for (final d in dosenList) {
        map[d.id!] = [];
      }

      for (final rel in relasiList) {
        final dId = rel['dosen_id'] as int?;
        final mId = rel['mahasiswa_id'] as int?;
        if (dId != null && mId != null) {
          final mData = rel['mahasiswa'] as Map<String, dynamic>?;
          if (mData != null) {
            final student = UserModel(
              id: mId,
              nama: mData['nama'] ?? 'Mahasiswa',
              nimNip: mData['nim_nip'] ?? '-',
              email: '',
              password: '',
              role: 'mahasiswa',
              jurusan: 'Teknik Informatika',
            );
            map.putIfAbsent(dId, () => []);
            map[dId]!.add(student);
          }
        }
      }

      if (mounted) {
        setState(() {
          _dosenList = dosenList;
          _allMahasiswaList = mahasiswaList;
          _dosenMahasiswaMap = map;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Dialog untuk mengubah dosen pembimbing dari seorang mahasiswa
  void _showChangePembimbingDialog(
    UserModel mahasiswa,
    UserModel currentDosen,
  ) {
    final primaryColor = Theme.of(context).primaryColor;
    UserModel? selectedDosen = currentDosen;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Ubah Dosen Pembimbing',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mahasiswa: ${mahasiswa.nama}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'NIM: ${mahasiswa.nimNip}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Dosen Pembimbing Baru:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserModel>(
                    value: _dosenList.any((d) => d.id == selectedDosen?.id)
                        ? _dosenList.firstWhere(
                            (d) => d.id == selectedDosen?.id,
                          )
                        : null,
                    isExpanded: true,
                    hint: const Text('Pilih Dosen'),
                    items: _dosenList
                        .map(
                          (d) =>
                              DropdownMenuItem(value: d, child: Text(d.nama)),
                        )
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedDosen = val;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed:
                  isSaving ||
                      selectedDosen == null ||
                      selectedDosen?.id == currentDosen.id
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      final success = await _service.setDosenPembimbing(
                        mahasiswa.id!,
                        selectedDosen!.id!,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);

                      if (success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Dosen pembimbing berhasil diubah!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                        _loadData();
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Gagal mengubah dosen pembimbing.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog untuk menentukan dosen pembimbing mahasiswa baru langsung ke dosen ini
  void _showAddStudentToDosenDialog(
    UserModel dosen,
    List<UserModel> currentStudents,
  ) {
    final primaryColor = Theme.of(context).primaryColor;
    UserModel? selectedMahasiswa;
    bool isSaving = false;

    // Dapatkan semua ID mahasiswa yang sudah memiliki dosen pembimbing
    final assignedStudentIds = _dosenMahasiswaMap.values
        .expand((list) => list)
        .map((m) => m.id)
        .toSet();

    // Filter mahasiswa yang belum memiliki dosen pembimbing sama sekali
    final availableStudents = _allMahasiswaList.where((m) {
      return !assignedStudentIds.contains(m.id);
    }).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Tambah Mahasiswa Bimbingan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dosen: ${dosen.nama}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Mahasiswa:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserModel>(
                    value: selectedMahasiswa,
                    isExpanded: true,
                    hint: const Text('Pilih Mahasiswa'),
                    items: availableStudents
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text('${m.nama} (${m.nimNip})'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedMahasiswa = val;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isSaving || selectedMahasiswa == null
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      final success = await _service.setDosenPembimbing(
                        selectedMahasiswa!.id!,
                        dosen.id!,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);

                      if (success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Mahasiswa bimbingan berhasil ditambahkan!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                        _loadData();
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Gagal menambahkan mahasiswa bimbingan.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
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
          'Daftar Dosen Pembimbing',
          style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: primaryColor),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dosenList.isEmpty
          ? const Center(
              child: Text(
                'Belum ada data dosen.',
                style: TextStyle(color: textGrey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _dosenList.length,
                itemBuilder: (context, index) {
                  final dosen = _dosenList[index];
                  final mahasiswaBimbingan =
                      _dosenMahasiswaMap[dosen.id!] ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            dosen.nama.isNotEmpty
                                ? dosen.nama[0].toUpperCase()
                                : 'D',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          dosen.nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textDark,
                          ),
                        ),
                        subtitle: Text(
                          'NIDN: ${dosen.nidn ?? "-"}\nBimbingan: ${mahasiswaBimbingan.length} Mahasiswa',
                          style: const TextStyle(fontSize: 12, color: textGrey),
                        ),
                        childrenPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        children: [
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 8),
                          if (mahasiswaBimbingan.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Text(
                                  'Belum ada mahasiswa bimbingan.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...mahasiswaBimbingan.map(
                              (m) => Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.nama,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: textDark,
                                            ),
                                          ),
                                          Text(
                                            'NIM: ${m.nimNip}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: textGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.swap_horiz_rounded,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          _showChangePembimbingDialog(m, dosen),
                                      tooltip: 'Ubah Pembimbing',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          // Tombol Tambah Mahasiswa khusus untuk Dosen ini
                          Center(
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showAddStudentToDosenDialog(
                                  dosen,
                                  mahasiswaBimbingan,
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text(
                                  'Tambah Mahasiswa',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: BorderSide(
                                    color: primaryColor.withValues(alpha: 0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
