import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progres_provider.dart';
import '../../database/supabase_service.dart';
import '../../models/user_model.dart';
import '../../models/konsultasi_model.dart';

class ProgresScreen extends StatefulWidget {
  const ProgresScreen({super.key});

  @override
  State<ProgresScreen> createState() => _ProgresScreenState();
}

class _ProgresScreenState extends State<ProgresScreen> {
  bool _dataLoaded = false;
  int? _dosenId;
  UserModel? _dosenPembimbing;
  String? _judulSkripsi;
  List<KonsultasiModel> _riwayatKonsultasi = [];
  bool _isLoadingKonsultasi = true;

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

    final progresProvider = context.read<ProgresProvider>();

    if (mounted) {
      setState(() {
        _isLoadingKonsultasi = true;
      });
    }

    try {
      final supabase = SupabaseService();

      // 1. Fetch lecturer ID and model
      final dosenId = await supabase.getDosenPembimbingByMahasiswa(user.id!);
      UserModel? dosen;
      if (dosenId != null) {
        dosen = await supabase.getUserById(dosenId);
      }

      // 2. Fetch thesis progress to get title if available
      await progresProvider.fetchTahapMahasiswa(user.id!);
      final tahapList = progresProvider.tahapMahasiswa;
      final judul = tahapList.isNotEmpty
          ? tahapList.first.judulSkripsi
          : 'Belum memasukkan judul skripsi';

      // 3. Fetch riwayat konsultasi
      final riwayat = await supabase.getKonsultasiByMahasiswa(user.id!);

      if (mounted) {
        setState(() {
          _dosenId = dosenId;
          _dosenPembimbing = dosen;
          _judulSkripsi = judul;
          _riwayatKonsultasi = riwayat;
          _isLoadingKonsultasi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingKonsultasi = false;
        });
      }
    }
  }

  void _showAddKonsultasiSheet() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    DateTime selectedDate = DateTime.now();
    final isiController = TextEditingController();
    String selectedStatus = 'acc';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tambah Riwayat Bimbingan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tanggal Picker Row
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateSheet(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tanggal: ${DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDate)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(
                              Icons.calendar_month,
                              color: Color(0xFF39A846),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Isi Konsultasi
                    TextField(
                      controller: isiController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Isi Konsultasi / Catatan Revisi',
                        hintText: 'Tulis hasil bimbingan hari ini...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'acc', child: Text('ACC')),
                        DropdownMenuItem(
                          value: 'revisi',
                          child: Text('Revisi'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setStateSheet(() => selectedStatus = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    // Simpan Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          if (isiController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Isi konsultasi harus diisi!'),
                              ),
                            );
                            return;
                          }

                          final dateStr =
                              '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

                          final newKonsultasi = KonsultasiModel(
                            mahasiswaId: user.id!,
                            dosenId: _dosenId,
                            tanggal: dateStr,
                            isiKonsultasi: isiController.text.trim(),
                            status: selectedStatus,
                            createdAt: DateTime.now().toIso8601String(),
                          );

                          if (mounted) {
                            setState(() {
                              _isLoadingKonsultasi = true;
                            });
                          }

                          Navigator.pop(ctx);

                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          try {
                            final supabase = SupabaseService();
                            final newId = await supabase.insertKonsultasi(
                              newKonsultasi,
                            );

                            if (newId > 0) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Berhasil menyimpan riwayat bimbingan',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Gagal menyimpan riwayat bimbingan',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Terjadi kesalahan: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }

                          await _loadData();
                        },
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteKonsultasi(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Hapus Riwayat',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text('Yakin ingin menghapus riwayat konsultasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              if (mounted) {
                setState(() {
                  _isLoadingKonsultasi = true;
                });
              }

              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                final supabase = SupabaseService();
                final success = await supabase.deleteKonsultasi(id);
                if (success > 0) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Riwayat bimbingan berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Gagal menghapus riwayat bimbingan'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Terjadi kesalahan: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }

              await _loadData();
            },
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditJudulDialog() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final controller = TextEditingController(
      text:
          (_judulSkripsi == 'Belum ditentukan' ||
              _judulSkripsi == 'Belum memasukkan judul skripsi')
          ? ''
          : _judulSkripsi,
    );
    final primaryColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Color(0xFF39A846)),
              SizedBox(width: 8),
              Text(
                'Edit Judul Skripsi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan judul skripsi Anda:',
                style: TextStyle(fontSize: 13, color: Color(0xFF9098B1)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tulis judul skripsi lengkap...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final newJudul = controller.text.trim();
                if (newJudul.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Judul skripsi tidak boleh kosong!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);

                if (mounted) {
                  setState(() {
                    _isLoadingKonsultasi = true;
                  });
                }

                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  final progresProvider = context.read<ProgresProvider>();
                  final success = await progresProvider.updateJudulSkripsi(
                    user.id!,
                    newJudul,
                  );

                  if (success) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Judul skripsi berhasil diperbarui'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Gagal memperbarui judul skripsi. Pastikan Anda sudah memiliki dosen pembimbing.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Terjadi kesalahan: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }

                await _loadData();
              },
              child: const Text(
                'Simpan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTanggal(String raw) {
    try {
      final date = DateTime.parse(raw);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return raw;
    }
  }

  Widget _buildHeaderCard(UserModel user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner / Header Lembar dengan background biru muda
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9), // Hijau muda
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.description_rounded,
                  color: Color(0xFF39A846),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Lembar Konsultasi Skripsi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ],
            ),
          ),
          // Detail Informasi Mahasiswa & Dosen
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow('Nama Mahasiswa', user.nama),
                const SizedBox(height: 8),
                _buildHeaderRow('NIM', user.nimNip),
                const SizedBox(height: 8),
                _buildHeaderRow(
                  'Judul Skripsi',
                  _judulSkripsi ?? 'Belum ditentukan',
                  onEdit: _showEditJudulDialog,
                ),
                const SizedBox(height: 8),
                _buildHeaderRow(
                  'Dosen Pembimbing',
                  _dosenPembimbing?.nama ?? 'Belum diinput ke sistem',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(String label, String value, {VoidCallback? onEdit}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9098B1),
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(fontSize: 12, color: Color(0xFF2D3142)),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ),
              if (onEdit != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF39A846).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: Color(0xFF39A846),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes_rounded, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Belum ada riwayat konsultasi.\nTap + untuk menambahkan.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9098B1),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final primaryColor = Theme.of(context).primaryColor;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Progres Skripsi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF9098B1)),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FloatingActionButton(
          backgroundColor: primaryColor,
          onPressed: _showAddKonsultasiSheet,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: _isLoadingKonsultasi
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(user),
                    const SizedBox(height: 24),
                    const Text(
                      'Riwayat Konsultasi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _riwayatKonsultasi.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _riwayatKonsultasi.length,
                            itemBuilder: (context, index) {
                              final item = _riwayatKonsultasi[index];
                              final isLast =
                                  index == _riwayatKonsultasi.length - 1;
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Timeline column
                                    Column(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          margin: const EdgeInsets.only(
                                            top: 14,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF39A846),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        if (!isLast)
                                          Expanded(
                                            child: Container(
                                              width: 2,
                                              color: const Color(
                                                0xFF39A846,
                                              ).withValues(alpha: 0.3),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    // Card content
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: GestureDetector(
                                          onLongPress: () =>
                                              _confirmDeleteKonsultasi(
                                                item.id!,
                                              ),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.03),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                              border: Border.all(
                                                color:
                                                    item.status.toLowerCase() ==
                                                        'acc'
                                                    ? const Color(
                                                        0xFF22C55E,
                                                      ).withValues(alpha: 0.2)
                                                    : const Color(
                                                        0xFFEF4444,
                                                      ).withValues(alpha: 0.2),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      _formatTanggal(
                                                        item.tanggal,
                                                      ),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                        color: Color(
                                                          0xFF39A846,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            item.status
                                                                    .toLowerCase() ==
                                                                'acc'
                                                            ? const Color(
                                                                0xFF22C55E,
                                                              ).withValues(
                                                                alpha: 0.1,
                                                              )
                                                            : const Color(
                                                                0xFFEF4444,
                                                              ).withValues(
                                                                alpha: 0.1,
                                                              ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        item.status
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          color:
                                                              item.status
                                                                      .toLowerCase() ==
                                                                  'acc'
                                                              ? const Color(
                                                                  0xFF22C55E,
                                                                )
                                                              : const Color(
                                                                  0xFFEF4444,
                                                                ),
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  item.isiKonsultasi,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF2D3142),
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
