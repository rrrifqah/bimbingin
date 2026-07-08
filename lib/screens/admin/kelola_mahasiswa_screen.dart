import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../database/supabase_service.dart';
import '../../models/user_model.dart';

/// Halaman untuk Staff mengelola data mahasiswa.
/// Staff dapat melihat, menambah, mengubah, dan menghapus data mahasiswa.
class KelolaMahasiswaScreen extends StatefulWidget {
  const KelolaMahasiswaScreen({super.key});

  @override
  State<KelolaMahasiswaScreen> createState() => _KelolaMahasiswaScreenState();
}

class _KelolaMahasiswaScreenState extends State<KelolaMahasiswaScreen> {
  List<UserModel> _mahasiswaList = [];
  List<UserModel> _filteredList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final SupabaseService _service = SupabaseService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Memuat daftar semua mahasiswa dari Supabase
  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final list = await _service.getAllMahasiswa();
      if (mounted) {
        setState(() {
          _mahasiswaList = list;
          _filteredList = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Filter mahasiswa berdasarkan query pencarian
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredList = _mahasiswaList;
      } else {
        _filteredList = _mahasiswaList.where((m) {
          final nama = m.nama.toLowerCase();
          final nim = m.nimNip.toLowerCase();
          final jurusan = m.jurusan.toLowerCase();
          return nama.contains(_searchQuery) ||
              nim.contains(_searchQuery) ||
              jurusan.contains(_searchQuery);
        }).toList();
      }
    });
  }

  /// Dialog untuk menambah atau mengubah data mahasiswa
  void _showMahasiswaDialog({UserModel? existing}) {
    final primaryColor = Theme.of(context).primaryColor;
    final namaCtrl = TextEditingController(text: existing?.nama ?? '');
    final nimCtrl = TextEditingController(text: existing?.nimNip ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final jurusanCtrl = TextEditingController(text: existing?.jurusan ?? '');
    final passwordCtrl = TextEditingController(text: existing?.password ?? '');
    bool isSubmitting = false;
    final isEdit = existing != null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(isEdit ? Icons.edit_outlined : Icons.person_add_outlined,
                  color: primaryColor),
              const SizedBox(width: 8),
              Text(isEdit ? 'Edit Mahasiswa' : 'Tambah Mahasiswa',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(namaCtrl, 'Nama Lengkap', Icons.person_outline),
                const SizedBox(height: 12),
                _buildTextField(nimCtrl, 'NIM', Icons.badge_outlined,
                    enabled: !isEdit),
                const SizedBox(height: 12),
                _buildTextField(emailCtrl, 'Email', Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _buildTextField(jurusanCtrl, 'Jurusan/Program Studi',
                    Icons.school_outlined),
                const SizedBox(height: 12),
                _buildTextField(passwordCtrl, 'Password',
                    Icons.lock_outline,
                    obscure: true),
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
                      if (namaCtrl.text.trim().isEmpty ||
                          nimCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Nama dan NIM wajib diisi!'),
                              backgroundColor: Colors.orange),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);

                      bool success = false;
                      if (isEdit) {
                        // Update mahasiswa
                        final updated = existing!.copyWith(
                          nama: namaCtrl.text.trim(),
                          jurusan: jurusanCtrl.text.trim(),
                        );
                        await _service.updateUser(updated);
                        success = true;
                      } else {
                        // Tambah mahasiswa baru
                        final newMahasiswa = UserModel(
                          nama: namaCtrl.text.trim(),
                          nimNip: nimCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: passwordCtrl.text.trim().isEmpty
                              ? '123456'
                              : passwordCtrl.text.trim(),
                          role: 'mahasiswa',
                          jurusan: jurusanCtrl.text.trim(),
                        );
                        final id = await _service.insertUser(newMahasiswa);
                        success = id > 0;
                      }

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? (isEdit
                                  ? 'Data mahasiswa berhasil diubah!'
                                  : 'Mahasiswa baru berhasil ditambahkan!')
                              : 'Gagal menyimpan data.'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                      if (success) _loadData();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(isEdit ? 'Simpan Perubahan' : 'Tambah',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// Konfirmasi hapus mahasiswa
  Future<void> _confirmDelete(UserModel mahasiswa) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Mahasiswa',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Hapus ${mahasiswa.nama}? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirm == true && mahasiswa.id != null) {
      await _service.deleteUser(mahasiswa.id!);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${mahasiswa.nama} berhasil dihapus.'),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  Widget _buildTextField(
      TextEditingController ctrl, String label, IconData icon,
      {bool obscure = false,
      bool enabled = true,
      TextInputType keyboardType = TextInputType.text}) {
    final primaryColor = Theme.of(context).primaryColor;
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
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
          'Kelola Mahasiswa',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMahasiswaDialog(),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Tambah Mahasiswa',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama, NIM, atau jurusan...',
                hintStyle: const TextStyle(color: textGrey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: textGrey),
                filled: true,
                fillColor: const Color(0xFFF4F7FB),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Info jumlah
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredList.length} mahasiswa',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: textGrey),
                ),
              ],
            ),
          ),

          // Daftar
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? const Center(
                        child: Text('Belum ada data mahasiswa.',
                            style: TextStyle(color: textGrey)))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _filteredList.length,
                          itemBuilder: (context, index) {
                            final m = _filteredList[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: primaryColor.withOpacity(0.1),
                                  child: Text(
                                    m.nama.isNotEmpty ? m.nama[0].toUpperCase() : 'M',
                                    style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  m.nama,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  'NIM: ${m.nimNip}\n${m.jurusan}',
                                  style: const TextStyle(
                                      fontSize: 12, color: textGrey),
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Edit
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined,
                                          color: primaryColor, size: 20),
                                      onPressed: () =>
                                          _showMahasiswaDialog(existing: m),
                                      tooltip: 'Edit',
                                    ),
                                    // Hapus
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 20),
                                      onPressed: () => _confirmDelete(m),
                                      tooltip: 'Hapus',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
