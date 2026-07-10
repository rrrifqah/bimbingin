import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../database/supabase_service.dart';
import '../../models/user_model.dart';
import '../../models/jadwal_model.dart';

/// Halaman Kelola Jadwal Dosen oleh Staff.
/// Staff dapat melihat, menambah, mengubah, dan menghapus jadwal seluruh dosen secara real-time.
class KelolaJadwalScreen extends StatefulWidget {
  const KelolaJadwalScreen({super.key});

  @override
  State<KelolaJadwalScreen> createState() => _KelolaJadwalScreenState();
}

class _KelolaJadwalScreenState extends State<KelolaJadwalScreen> {
  final SupabaseService _service = SupabaseService();
  List<Map<String, dynamic>> _schedules = [];
  List<UserModel> _dosenList = [];
  bool _isLoading = true;
  int? _selectedDosenIdFilter; // Filter dosen di halaman utama

  RealtimeChannel? _jadwalChannel;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupRealtime();
  }

  @override
  void dispose() {
    final client = Supabase.instance.client;
    if (_jadwalChannel != null) {
      client.removeChannel(_jadwalChannel!);
    }
    super.dispose();
  }

  /// Setup listener Supabase Realtime agar jadwal di-update otomatis
  void _setupRealtime() {
    final client = Supabase.instance.client;
    _jadwalChannel = client
        .channel('public-jadwal-changes-kelola-screen')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jadwal_dosen',
          callback: (payload) {
            if (mounted) {
              _loadSchedulesOnly();
            }
          },
        );
    _jadwalChannel?.subscribe();
  }

  Future<void> _loadInitialData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getMonitoringJadwal(),
        _service.getAllDosen(),
      ]);
      if (mounted) {
        setState(() {
          _schedules = results[0] as List<Map<String, dynamic>>;
          _dosenList = results[1] as List<UserModel>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSchedulesOnly() async {
    try {
      final list = await _service.getMonitoringJadwal();
      if (mounted) {
        setState(() {
          _schedules = list;
        });
      }
    } catch (_) {}
  }

  String _formatTanggal(String? tanggal) {
    if (tanggal == null || tanggal.isEmpty) return '';
    try {
      return DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.parse(tanggal));
    } catch (_) {
      return tanggal;
    }
  }

  void _showAddJadwalBottomSheet() {
    final primaryColor = Theme.of(context).primaryColor;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _AddEditJadwalBottomSheet(
          primaryColor: primaryColor,
          dosenList: _dosenList,
          isEdit: false,
          onSave: _loadSchedulesOnly,
        );
      },
    );
  }

  void _showEditJadwalBottomSheet(JadwalModel jadwal) {
    final primaryColor = Theme.of(context).primaryColor;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _AddEditJadwalBottomSheet(
          primaryColor: primaryColor,
          dosenList: _dosenList,
          isEdit: true,
          jadwal: jadwal,
          onSave: _loadSchedulesOnly,
        );
      },
    );
  }

  Future<void> _deleteJadwal(Map<String, dynamic> scheduleData) async {
    final jId = scheduleData['id'] as int;
    final hari = scheduleData['hari'] ?? '';
    final jamMulai = scheduleData['jam_mulai'] ?? '';
    final jamSelesai = scheduleData['jam_selesai'] ?? '';
    final namaDosen = scheduleData['dosen']?['nama'] ?? 'Dosen';

    // Cek booking aktif terlebih dahulu
    final bookings = await _service.getBookingByJadwalActive(jId);

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Jadwal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          bookings.isNotEmpty
              ? 'PERINGATAN: Jadwal bimbingan $namaDosen ($hari, $jamMulai-$jamSelesai) memiliki ${bookings.length} booking aktif dari mahasiswa.\n\n'
                    'Apakah Anda yakin ingin tetap menghapus jadwal ini?'
              : 'Apakah Anda yakin ingin menghapus jadwal bimbingan $namaDosen ($hari, $jamMulai-$jamSelesai)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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

    if (confirm == true && mounted) {
      final result = await _service.deleteJadwal(jId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result > 0
                  ? 'Jadwal berhasil dihapus.'
                  : 'Gagal menghapus jadwal.',
            ),
            backgroundColor: result > 0 ? Colors.green : Colors.red,
          ),
        );
        _loadSchedulesOnly();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    // Filter list jadwal berdasarkan filter dosen
    final filteredSchedules = _selectedDosenIdFilter == null
        ? _schedules
        : _schedules
              .where((s) => s['dosen_id'] == _selectedDosenIdFilter)
              .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Kelola Jadwal Dosen',
          style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Dropdown Panel
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: textGrey, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int?>(
                              value: _selectedDosenIdFilter,
                              hint: const Text(
                                'Tampilkan Semua Dosen',
                                style: TextStyle(fontSize: 13, color: textGrey),
                              ),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text(
                                    'Tampilkan Semua Dosen',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                ..._dosenList.map((d) {
                                  return DropdownMenuItem<int?>(
                                    value: d.id,
                                    child: Text(
                                      d.nama,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedDosenIdFilter = val;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // List Schedules
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadInitialData,
                    child: filteredSchedules.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Tidak Ada Jadwal',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _selectedDosenIdFilter == null
                                          ? 'Belum ada jadwal dosen yang dibuka.'
                                          : 'Dosen yang dipilih belum memiliki jadwal.',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: textGrey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredSchedules.length,
                            itemBuilder: (context, index) {
                              final map = filteredSchedules[index];
                              final j = JadwalModel.fromMap(map);
                              final namaDosen =
                                  map['dosen']?['nama'] ?? 'Dosen';
                              final fotoDosen =
                                  map['dosen']?['foto'] as String?;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    backgroundImage:
                                        (fotoDosen != null &&
                                            fotoDosen.startsWith('http'))
                                        ? NetworkImage(fotoDosen)
                                        : null,
                                    child:
                                        (fotoDosen == null ||
                                            !fotoDosen.startsWith('http'))
                                        ? Text(
                                            namaDosen.isNotEmpty
                                                ? namaDosen[0].toUpperCase()
                                                : 'D',
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    namaDosen,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textDark,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_month,
                                            size: 13,
                                            color: textGrey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            (j.tanggal != null &&
                                                    j.tanggal!.isNotEmpty)
                                                ? '${j.hari}, ${_formatTanggal(j.tanggal)}'
                                                : j.hari,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: textDark,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time_rounded,
                                            size: 13,
                                            color: textGrey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${j.jamMulai} - ${j.jamSelesai} (${j.status.toUpperCase()})',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: j.status == 'tersedia'
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Slot Terisi: ${j.kuota - j.sisaSlot}/${j.kuota}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          color: primaryColor,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _showEditJadwalBottomSheet(j),
                                        tooltip: 'Ubah Jadwal',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        onPressed: () => _deleteJadwal(map),
                                        tooltip: 'Hapus Jadwal',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddJadwalBottomSheet,
        backgroundColor: primaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

/// Bottom Sheet untuk tambah/edit jadwal dosen
class _AddEditJadwalBottomSheet extends StatefulWidget {
  final Color primaryColor;
  final List<UserModel> dosenList;
  final bool isEdit;
  final JadwalModel? jadwal;
  final VoidCallback onSave;

  const _AddEditJadwalBottomSheet({
    required this.primaryColor,
    required this.dosenList,
    required this.isEdit,
    this.jadwal,
    required this.onSave,
  });

  @override
  State<_AddEditJadwalBottomSheet> createState() =>
      _AddEditJadwalBottomSheetState();
}

class _AddEditJadwalBottomSheetState extends State<_AddEditJadwalBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedDosenId;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _slotController = TextEditingController(
    text: '5',
  );
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.jadwal != null) {
      final j = widget.jadwal!;
      _selectedDosenId = j.dosenId;
      _lokasiController.text = j.lokasi ?? '';
      _keteranganController.text = j.keterangan ?? '';
      _slotController.text = j.kuota.toString();

      try {
        if (j.tanggal != null && j.tanggal!.isNotEmpty) {
          _selectedDate = DateTime.parse(j.tanggal!);
        }
      } catch (_) {}

      try {
        final startParts = j.jamMulai.split(':');
        _startTime = TimeOfDay(
          hour: int.parse(startParts[0]),
          minute: int.parse(startParts[1]),
        );
      } catch (_) {}

      try {
        final endParts = j.jamSelesai.split(':');
        _endTime = TimeOfDay(
          hour: int.parse(endParts[0]),
          minute: int.parse(endParts[1]),
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _slotController.dispose();
    _lokasiController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  bool _isTimeOverlapping(
    String start1,
    String end1,
    String start2,
    String end2,
  ) {
    try {
      final startMin1 = _parseTimeToMinutes(start1);
      final endMin1 = _parseTimeToMinutes(end1);
      final startMin2 = _parseTimeToMinutes(start2);
      final endMin2 = _parseTimeToMinutes(end2);
      return startMin1 < endMin2 && startMin2 < endMin1;
    } catch (_) {
      return false;
    }
  }

  int _parseTimeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.primaryColor,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF2D3142),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDateDisplay(DateTime? date) {
    if (date == null) return 'Pilih Tanggal';
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return date.toString().substring(0, 10);
    }
  }

  String _formatDateDb(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _getDayName(DateTime date) {
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days[date.weekday - 1];
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? const TimeOfDay(hour: 8, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 10, minute: 0)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.primaryColor,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF2D3142),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDosenId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Dosen!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Tanggal Bimbingan!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Jam Mulai dan Jam Selesai!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam Selesai harus setelah Jam Mulai!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final kuota = int.parse(_slotController.text.trim());
    final tanggalDb = _formatDateDb(_selectedDate!);
    final jamMulai = _formatTimeOfDay(_startTime);
    final jamSelesai = _formatTimeOfDay(_endTime);

    final service = SupabaseService();

    // 1. Cek Booking jika EDIT MODE
    int activeBookingsCount = 0;
    if (widget.isEdit && widget.jadwal != null) {
      try {
        final bookings = await service.getBookingByJadwalActive(
          widget.jadwal!.id!,
        );
        activeBookingsCount = bookings.length;

        if (!mounted) return;

        // Validasi kuota tidak boleh kurang dari booking aktif
        if (kuota < activeBookingsCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Kuota tidak boleh kurang dari jumlah booking aktif ($activeBookingsCount)!',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isSubmitting = false);
          return;
        }

        // Tampilkan dialog konfirmasi jika jadwal memiliki booking aktif
        if (activeBookingsCount > 0) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Ubah Jadwal?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              content: Text(
                'Jadwal ini sudah memiliki $activeBookingsCount booking aktif dari mahasiswa.\n\n'
                'Apakah Anda yakin ingin mengubah jadwal ini? Mahasiswa yang sudah booking akan tetap berada di antrean.',
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                  ),
                  child: const Text(
                    'Ya, Ubah',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
          if (confirm != true) {
            setState(() => _isSubmitting = false);
            return;
          }
        }
      } catch (_) {}
    }

    // 2. Cek Overlap/Bentrok Jadwal
    try {
      final existingSchedules = await service.getJadwalByTanggal(
        _selectedDosenId!,
        tanggalDb,
      );
      bool isBentrok = false;
      for (final j in existingSchedules) {
        if (widget.isEdit &&
            widget.jadwal != null &&
            j.id == widget.jadwal!.id) {
          continue; // Lewati jadwal yang sedang diedit
        }
        if (_isTimeOverlapping(
          jamMulai,
          jamSelesai,
          j.jamMulai,
          j.jamSelesai,
        )) {
          isBentrok = true;
          break;
        }
      }
      if (isBentrok) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jadwal dosen pada waktu tersebut sudah tersedia.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } catch (_) {}

    // Hitung sisa slot baru
    final newSisaSlot = widget.isEdit && widget.jadwal != null
        ? kuota - activeBookingsCount
        : kuota;
    final newStatus = newSisaSlot <= 0 ? 'penuh' : 'tersedia';

    bool success = false;

    try {
      if (widget.isEdit && widget.jadwal != null) {
        final updatedJadwal = widget.jadwal!.copyWith(
          hari: _getDayName(_selectedDate!),
          tanggal: tanggalDb,
          jamMulai: jamMulai,
          jamSelesai: jamSelesai,
          kuota: kuota,
          sisaSlot: newSisaSlot,
          status: newStatus,
          lokasi: _lokasiController.text.trim(),
          keterangan: _keteranganController.text.trim(),
        );
        final result = await service.updateJadwal(updatedJadwal);
        success = result > 0;
      } else {
        final newJadwal = JadwalModel(
          dosenId: _selectedDosenId!,
          hari: _getDayName(_selectedDate!),
          tanggal: tanggalDb,
          jamMulai: jamMulai,
          jamSelesai: jamSelesai,
          status: 'tersedia',
          kuota: kuota,
          sisaSlot: kuota,
          lokasi: _lokasiController.text.trim(),
          keterangan: _keteranganController.text.trim(),
        );
        final result = await service.insertJadwal(newJadwal);
        success = result > 0;
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isEdit
                    ? 'Jadwal berhasil diubah!'
                    : 'Jadwal baru berhasil ditambahkan!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSave();
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan jadwal.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF2D3142);
    final dosenName = widget.isEdit && widget.jadwal != null
        ? (widget.dosenList
              .firstWhere(
                (d) => d.id == widget.jadwal!.dosenId,
                orElse: () => UserModel(
                  id: widget.jadwal!.dosenId,
                  nama: 'Dosen ID ${widget.jadwal!.dosenId}',
                  nimNip: '',
                  email: '',
                  password: '',
                  role: 'dosen',
                  jurusan: '',
                ),
              )
              .nama)
        : '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  widget.isEdit
                      ? 'Ubah Jadwal Dosen'
                      : 'Buka Jadwal Dosen Baru',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 20),

                // Pilih Dosen
                const Text(
                  'Pilih Dosen',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                widget.isEdit
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          dosenName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _selectedDosenId,
                            hint: const Text(
                              'Pilih Dosen Bimbingan',
                              style: TextStyle(fontSize: 13),
                            ),
                            isExpanded: true,
                            items: widget.dosenList.map((d) {
                              return DropdownMenuItem<int?>(
                                value: d.id,
                                child: Text(
                                  d.nama,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedDosenId = val;
                              });
                            },
                          ),
                        ),
                      ),
                const SizedBox(height: 16),

                // Tanggal Bimbingan
                const Text(
                  'Tanggal Bimbingan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'Pilih Tanggal'
                              : _formatDateDisplay(_selectedDate),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedDate == null
                                ? Colors.grey
                                : textDark,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          color: widget.primaryColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Jam Mulai & Jam Selesai Row
                Row(
                  children: [
                    // Jam Mulai
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jam Mulai',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectTime(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatTimeOfDay(_startTime),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    color: widget.primaryColor,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Jam Selesai
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jam Selesai',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectTime(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatTimeOfDay(_endTime),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    color: widget.primaryColor,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Lokasi (Opsional)
                const Text(
                  'Lokasi Bimbingan (Opsional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lokasiController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    hintText: 'Contoh: Ruang Rektorat / Daring via Zoom',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Keterangan (Opsional)
                const Text(
                  'Keterangan Tambahan (Opsional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _keteranganController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    hintText: 'Masukkan catatan tambahan...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Kuota Bimbingan
                const Text(
                  'Kuota Bimbingan (Kuota)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _slotController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    hintText: 'Contoh: 5',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Kuota harus diisi!';
                    }
                    final count = int.tryParse(val.trim());
                    if (count == null || count < 1) {
                      return 'Minimal kuota 1 slot!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Button Simpan
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.isEdit ? 'Ubah Jadwal' : 'Simpan Jadwal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
