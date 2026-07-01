import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class TargetProvider with ChangeNotifier {
  Map<String, dynamic>? _targetMahasiswa;
  List<Map<String, dynamic>> _allTargets = [];
  bool _isLoading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Map<String, dynamic>? get targetMahasiswa => _targetMahasiswa;
  List<Map<String, dynamic>> get allTargets => _allTargets;
  bool get isLoading => _isLoading;

  /// Hitung sisa hari dari target_selesai ke sekarang
  static int hitungSisaHari(String targetSelesai) {
    try {
      final target = DateTime.parse(targetSelesai);
      final now = DateTime.now();
      final diff = target.difference(DateTime(now.year, now.month, now.day));
      return diff.inDays;
    } catch (e) {
      return 0;
    }
  }

  /// Warna indikator berdasarkan sisa hari
  static Color warnaIndikator(int sisaHari) {
    if (sisaHari > 30) return const Color(0xFF22C55E); // hijau
    if (sisaHari >= 10) return const Color(0xFFF59E0B); // kuning
    return const Color(0xFFEF4444); // merah
  }

  Future<void> fetchTargetMahasiswa(int mahasiswaId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _targetMahasiswa = await _dbHelper.getTargetByMahasiswa(mahasiswaId);
    } catch (e) {
      _targetMahasiswa = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllTargetByDosen(int dosenId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _allTargets = await _dbHelper.getAllTargetByDosen(dosenId);
    } catch (e) {
      _allTargets = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> upsertTarget(
      int mahasiswaId, String targetSelesai, int createdBy) async {
    try {
      final result =
          await _dbHelper.upsertTarget(mahasiswaId, targetSelesai, createdBy);
      if (result > 0) {
        // Refresh
        _targetMahasiswa = await _dbHelper.getTargetByMahasiswa(mahasiswaId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
