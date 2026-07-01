import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/target_provider.dart';
import '../../database/database_helper.dart';
import '../../models/user_model.dart';
import '../../models/progres_model.dart';

class UpdateProgresScreen extends StatefulWidget {
  const UpdateProgresScreen({super.key});

  @override
  State<UpdateProgresScreen> createState() => _UpdateProgresScreenState();
}

class _UpdateProgresScreenState extends State<UpdateProgresScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data
  List<UserModel> _allMahasiswa = [];
  Map<int, List<ProgresModel>> _progresGrouped = {};
  bool _isLoading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Form state
  UserModel? _selectedMahasiswa;
  String _selectedTahap = 'bab1';
  String _selectedStatus = 'acc';
  final TextEditingController _notesController = TextEditingController();

  final List<String> _tahapOptions = [
    'bab1', 'bab2', 'bab3', 'seminar_proposal', 'bab4_5', 'sidang', 'selesai'
  ];
  final List<String> _statusOptions = [
    'acc', 'revisi', 'menunggu_konfirmasi', 'belum'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _allMahasiswa = await _dbHelper.getAllMahasiswa();
      if (_selectedMahasiswa == null && _allMahasiswa.isNotEmpty) {
        _selectedMahasiswa = _allMahasiswa.first;
      }

      // Load progres for all mahasiswa
      _progresGrouped = {};
      for (final m in _allMahasiswa) {
        final list = await _dbHelper.getAllTahapByMahasiswa(m.id!);
        _progresGrouped[m.id!] = list;
      }
    } catch (e) {
      _allMahasiswa = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateProgres() async {
    if (_selectedMahasiswa == null) return;

    final tahapList = _progresGrouped[_selectedMahasiswa!.id!] ?? [];
    final progres = tahapList.where((p) => p.tahap == _selectedTahap).firstOrNull;

    if (progres == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data tahap tidak ditemukan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _dbHelper.updateStatusProgresById(
          progres.id!, _selectedStatus, _notesController.text.trim());

      _notesController.clear();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Progres "${_tahapLabel(_selectedTahap)}" untuk ${_selectedMahasiswa!.nama} berhasil diperbarui.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _setTarget() async {
    if (_selectedMahasiswa == null) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 60)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'Pilih Target Selesai Skripsi',
    );

    if (picked == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final targetStr =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      final success = await context.read<TargetProvider>().upsertTarget(
          _selectedMahasiswa!.id!, targetStr, user.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Target selesai untuk ${_selectedMahasiswa!.nama} berhasil ditetapkan.'
                : 'Gagal menetapkan target.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _tahapLabel(String tahap) {
    switch (tahap) {
      case 'bab1': return 'Bab 1: Pendahuluan';
      case 'bab2': return 'Bab 2: Tinjauan Pustaka';
      case 'bab3': return 'Bab 3: Metodologi';
      case 'seminar_proposal': return 'Seminar Proposal';
      case 'bab4_5': return 'Bab 4 & 5: Implementasi';
      case 'sidang': return 'Sidang Skripsi';
      case 'selesai': return 'Selesai';
      default: return tahap;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'acc': return 'ACC';
      case 'revisi': return 'Revisi';
      case 'menunggu_konfirmasi': return 'Menunggu Konfirmasi';
      default: return 'Belum';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'acc': return const Color(0xFF22C55E);
      case 'revisi': return const Color(0xFFEF4444);
      case 'menunggu_konfirmasi': return const Color(0xFFF59E0B);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    final tahapList = _selectedMahasiswa != null
        ? (_progresGrouped[_selectedMahasiswa!.id!] ?? [])
        : <ProgresModel>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Update Progres & Target',
          style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF9098B1)),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: textGrey,
          indicatorColor: primaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Update Progres'),
            Tab(text: 'Target Selesai'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allMahasiswa.isEmpty
              ? const Center(
                  child: Text('Belum ada data mahasiswa.',
                      style: TextStyle(color: Color(0xFF9098B1))))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Update Progres
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Form Card
                          Container(
                            padding: const EdgeInsets.all(20),
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
                                const Text(
                                  'Input Pembaruan Progres',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textDark),
                                ),
                                const SizedBox(height: 16),

                                // Pilih Mahasiswa
                                const Text('Pilih Mahasiswa',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textDark)),
                                const SizedBox(height: 8),
                                _buildDropdown(
                                  value: _selectedMahasiswa?.id?.toString(),
                                  items: _allMahasiswa
                                      .map((m) => DropdownMenuItem<String>(
                                            value: m.id.toString(),
                                            child: Text(
                                                '${m.nama} (${m.nimNip})',
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val == null) return;
                                    setState(() {
                                      _selectedMahasiswa =
                                          _allMahasiswa.firstWhere(
                                              (m) =>
                                                  m.id.toString() == val);
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Pilih Tahap + Status
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Tahap',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: textDark)),
                                          const SizedBox(height: 8),
                                          _buildDropdown(
                                            value: _selectedTahap,
                                            items: _tahapOptions
                                                .map((t) =>
                                                    DropdownMenuItem<String>(
                                                      value: t,
                                                      child: Text(
                                                          _tahapLabel(t)
                                                              .split(':')[0],
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      13)),
                                                    ))
                                                .toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() =>
                                                    _selectedTahap = val);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Status',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: textDark)),
                                          const SizedBox(height: 8),
                                          _buildDropdown(
                                            value: _selectedStatus,
                                            items: _statusOptions
                                                .map((s) =>
                                                    DropdownMenuItem<String>(
                                                      value: s,
                                                      child: Text(
                                                          _statusLabel(s),
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      13)),
                                                    ))
                                                .toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() =>
                                                    _selectedStatus = val);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Catatan
                                const Text('Catatan / Feedback',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textDark)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _notesController,
                                  maxLines: 3,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Tuliskan catatan perbaikan atau detail ACC...',
                                    hintStyle: const TextStyle(
                                        color: textGrey,
                                        fontWeight: FontWeight.normal),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding:
                                        const EdgeInsets.all(12),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade200),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade200),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: primaryColor, width: 1.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _updateProgres,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Update Progres',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Current Progress Detail
                          if (_selectedMahasiswa != null) ...[
                            Text(
                              'Detail Progres: ${_selectedMahasiswa!.nama}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark),
                            ),
                            const SizedBox(height: 12),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: tahapList.length,
                              itemBuilder: (context, i) {
                                final p = tahapList[i];
                                final color = _statusColor(p.status);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: Colors.grey.shade100),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _tahapLabel(p.tahap),
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 13,
                                                  color: textDark),
                                            ),
                                            if (p.catatan != null &&
                                                p.catatan!.isNotEmpty)
                                              Text(
                                                p.catatan!,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: textGrey),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              )
                                            else
                                              Text(
                                                _statusLabel(p.status),
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: textGrey),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _statusLabel(p.status),
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: color),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // Tab 2: Target Selesai — FITUR 2
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
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
                                const Text(
                                  'Tetapkan Target Selesai Skripsi',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textDark),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Pilih mahasiswa dan tentukan tanggal target selesai skripsinya.',
                                  style: TextStyle(
                                      fontSize: 12, color: textGrey),
                                ),
                                const SizedBox(height: 16),

                                const Text('Pilih Mahasiswa',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textDark)),
                                const SizedBox(height: 8),
                                _buildDropdown(
                                  value: _selectedMahasiswa?.id?.toString(),
                                  items: _allMahasiswa
                                      .map((m) => DropdownMenuItem<String>(
                                            value: m.id.toString(),
                                            child: Text(
                                                '${m.nama} (${m.nimNip})',
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val == null) return;
                                    setState(() {
                                      _selectedMahasiswa =
                                          _allMahasiswa.firstWhere(
                                              (m) =>
                                                  m.id.toString() == val);
                                    });
                                  },
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: _setTarget,
                                    icon: const Icon(Icons.calendar_month,
                                        color: Colors.white),
                                    label: const Text(
                                      'Pilih Tanggal Target',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Daftar target semua mahasiswa
                          const Text(
                            'Target Semua Mahasiswa',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textDark),
                          ),
                          const SizedBox(height: 12),
                          Consumer<TargetProvider>(
                            builder: (ctx, targetProvider, _) {
                              // Since this is admin, show from all mahasiswa directly
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _allMahasiswa.length,
                                itemBuilder: (context, i) {
                                  final m = _allMahasiswa[i];
                                  // We need to get target per mahasiswa
                                  // Let's use FutureBuilder for each
                                  return FutureBuilder<Map<String, dynamic>?>(
                                    future: _dbHelper.getTargetByMahasiswa(m.id!),
                                    builder: (ctx, snap) {
                                      final target = snap.data;
                                      final targetSelesai =
                                          target?['target_selesai'] as String?;
                                      final sisaHari = targetSelesai != null
                                          ? TargetProvider.hitungSisaHari(
                                              targetSelesai)
                                          : null;
                                      final warna = sisaHari != null
                                          ? TargetProvider.warnaIndikator(
                                              sisaHari)
                                          : Colors.grey;

                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.grey.shade100),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: primaryColor
                                                  .withValues(alpha: 0.1),
                                              child: Text(
                                                m.nama.isNotEmpty
                                                    ? m.nama[0]
                                                    : 'M',
                                                style: TextStyle(
                                                    color: primaryColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(m.nama,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: textDark)),
                                                  Text(m.nimNip,
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: textGrey)),
                                                ],
                                              ),
                                            ),
                                            if (targetSelesai != null)
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    targetSelesai,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: warna,
                                                    ),
                                                  ),
                                                  Text(
                                                    sisaHari! < 0
                                                        ? 'Lewat ${sisaHari.abs()} hari'
                                                        : '$sisaHari hari lagi',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: warna),
                                                  ),
                                                ],
                                              )
                                            else
                                              const Text(
                                                'Belum ditetapkan',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        Color(0xFF9098B1)),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
