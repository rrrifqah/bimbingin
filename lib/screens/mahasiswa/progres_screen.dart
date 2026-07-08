import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progres_provider.dart';
import '../../models/progres_model.dart';
import '../../providers/target_provider.dart';
import '../../database/supabase_service.dart';

class ProgresScreen extends StatefulWidget {
  const ProgresScreen({super.key});

  @override
  State<ProgresScreen> createState() => _ProgresScreenState();
}

class _ProgresScreenState extends State<ProgresScreen> {
  bool _dataLoaded = false;
  int? _dosenId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      _dataLoaded = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await context.read<ProgresProvider>().fetchTahapMahasiswa(user.id!);
    
    // Fetch target for the visual indicator
    await context.read<TargetProvider>().fetchTargetMahasiswa(user.id!);

    // Dapatkan dosen pembimbing untuk membuat progres baru
    final supabase = SupabaseService();
    _dosenId = await supabase.getDosenPembimbingByMahasiswa(user.id!);
  }

  void _showFormProgres({ProgresModel? existingProgres}) {
    final isEdit = existingProgres != null;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    if (!isEdit && _dosenId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda belum memiliki dosen pembimbing.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final judulController = TextEditingController(
        text: isEdit
            ? existingProgres.judulSkripsi
            : (context.read<ProgresProvider>().tahapMahasiswa.isNotEmpty
                ? context.read<ProgresProvider>().tahapMahasiswa.first.judulSkripsi
                : ''));
    final catatanController =
        TextEditingController(text: isEdit ? existingProgres.catatanMahasiswa : '');
    
    String selectedTahap = isEdit ? existingProgres.tahap : 'bab1';
    
    final List<String> tahapOptions = [
      'bab1', 'bab2', 'bab3', 'seminar_proposal', 'bab4_5', 'sidang', 'selesai'
    ];

    String getTahapLabel(String t) {
      switch (t) {
        case 'bab1': return 'Bab 1: Pendahuluan';
        case 'bab2': return 'Bab 2: Tinjauan Pustaka';
        case 'bab3': return 'Bab 3: Metodologi';
        case 'seminar_proposal': return 'Seminar Proposal';
        case 'bab4_5': return 'Bab 4 & 5: Implementasi';
        case 'sidang': return 'Sidang Skripsi';
        case 'selesai': return 'Selesai';
        default: return t;
      }
    }

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
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Edit Progres' : 'Tambah Progres',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: judulController,
                    decoration: InputDecoration(
                      labelText: 'Judul Skripsi',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedTahap,
                    decoration: InputDecoration(
                      labelText: 'Tahap',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: tahapOptions.map((t) {
                      return DropdownMenuItem(value: t, child: Text(getTahapLabel(t)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setStateSheet(() => selectedTahap = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: catatanController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Catatan / Laporan Progres',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        if (judulController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Judul tidak boleh kosong!')),
                          );
                          return;
                        }

                        final provider = context.read<ProgresProvider>();
                        bool success = false;
                        
                        if (isEdit) {
                          final updated = existingProgres.copyWith(
                            judulSkripsi: judulController.text.trim(),
                            tahap: selectedTahap,
                            catatanMahasiswa: catatanController.text.trim(),
                          );
                          success = await provider.editProgres(updated);
                        } else {
                          final newProgres = ProgresModel(
                            mahasiswaId: user.id!,
                            dosenId: _dosenId!,
                            judulSkripsi: judulController.text.trim(),
                            tahap: selectedTahap,
                            status: 'menunggu_konfirmasi',
                            catatanMahasiswa: catatanController.text.trim(),
                            updatedAt: DateTime.now().toIso8601String(),
                          );
                          success = await provider.tambahProgres(newProgres);
                        }

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Berhasil menyimpan progres' : 'Gagal menyimpan progres'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      },
                      child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(int progresId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Progres'),
        content: const Text('Yakin ingin menghapus progres ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await context.read<ProgresProvider>().hapusProgres(progresId);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Progres dihapus' : 'Gagal menghapus'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progresProvider = context.watch<ProgresProvider>();
    final targetProvider = context.watch<TargetProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final primaryColor = Theme.of(context).primaryColor;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final tahapList = progresProvider.tahapMahasiswa;
    final accCount = tahapList.where((p) => p.status == 'acc').length;
    final total = tahapList.length;
    final pct = total > 0 ? accCount / total : 0.0;
    
    // Fitur 2: Visual indikator target waktu
    final targetData = targetProvider.targetMahasiswa;
    final targetSelesai = targetData?['target_selesai'] as String?;
    
    String statusTarget = 'Belum Ada Target';
    Color warnaTarget = Colors.grey;
    if (targetSelesai != null) {
        final sisaHari = TargetProvider.hitungSisaHari(targetSelesai);
        final isSelesai = tahapList.any((p) => p.tahap == 'selesai' && p.status == 'acc');
        
        if (isSelesai) {
             final selesaiUpdate = tahapList.firstWhere((p) => p.tahap == 'selesai' && p.status == 'acc').updatedAt;
             final compDate = DateTime.parse(selesaiUpdate);
             final targetDate = DateTime.parse(targetSelesai);
             final c = DateTime(compDate.year, compDate.month, compDate.day);
             final t = DateTime(targetDate.year, targetDate.month, targetDate.day);
             if (c.isBefore(t) || c.isAtSameMomentAs(t)) {
                 statusTarget = 'Selesai Tepat Waktu';
                 warnaTarget = Colors.green;
             } else {
                 statusTarget = 'Target Terlewati';
                 warnaTarget = Colors.red;
             }
        } else {
            if (sisaHari < 0) {
                statusTarget = 'Target Terlewati';
                warnaTarget = Colors.red;
            } else {
                statusTarget = 'Dalam Target (Sisa $sisaHari Hari)';
                warnaTarget = Colors.blue;
            }
        }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Progres Skripsi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadData,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => _showFormProgres(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: progresProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target Status Card (FITUR 2)
                    if (targetSelesai != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: warnaTarget.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: warnaTarget.withOpacity(0.3))
                        ),
                        child: Row(
                            children: [
                                Icon(Icons.flag, color: warnaTarget),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text('Target Waktu: ${DateFormat('dd MMM yyyy').format(DateTime.parse(targetSelesai))}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text(statusTarget, style: TextStyle(color: warnaTarget, fontWeight: FontWeight.bold, fontSize: 13)),
                                        ]
                                    )
                                )
                            ]
                        )
                      ),
                      
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ringkasan Capaian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(Icons.star, color: primaryColor),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$accCount dari $total Tahap Selesai', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(value: pct, backgroundColor: Colors.grey.shade200, color: primaryColor),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Timeline
                    const Text('Timeline Tahapan Skripsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (tahapList.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada progres.')))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tahapList.length,
                        itemBuilder: (context, index) {
                          final stage = tahapList[index];
                          Color statusColor;
                          String statusLabel;
                          
                          switch (stage.status) {
                            case 'acc': statusColor = Colors.green; statusLabel = 'ACC'; break;
                            case 'revisi': statusColor = Colors.red; statusLabel = 'Revisi'; break;
                            case 'menunggu_konfirmasi': statusColor = Colors.orange; statusLabel = 'Menunggu'; break;
                            default: statusColor = Colors.grey; statusLabel = 'Belum';
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                              Text(stage.tahapLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                              )
                                          ]
                                      ),
                                      if (stage.catatanMahasiswa != null && stage.catatanMahasiswa!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text('Catatan saya: ${stage.catatanMahasiswa}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                        ),
                                      if (stage.catatan != null && stage.catatan!.isNotEmpty)
                                        Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text('Catatan Dosen: ${stage.catatan}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey))
                                        )
                                    ],
                                  ),
                                ),
                                Row(
                                    children: [
                                        IconButton(
                                            icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                            onPressed: () => _showFormProgres(existingProgres: stage),
                                        ),
                                        IconButton(
                                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                            onPressed: () => _confirmDelete(stage.id!),
                                        ),
                                    ]
                                )
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
