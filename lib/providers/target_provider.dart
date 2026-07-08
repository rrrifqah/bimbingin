import 'package:flutter/material.dart';
import '../database/supabase_service.dart';

class TargetProvider with ChangeNotifier {
  Map<String, dynamic>? _targetMahasiswa;
  List<Map<String, dynamic>> _allTargets = [];
  bool _isLoading = false;
  final SupabaseService _service = SupabaseService();

  Map<String, dynamic>? get targetMahasiswa => _targetMahasiswa;
  List<Map<String, dynamic>> get allTargets => _allTargets;
  bool get isLoading => _isLoading;

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

  static Color warnaIndikator(int sisaHari) {
    if (sisaHari > 30) return const Color(0xFF22C55E);
    if (sisaHari >= 10) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Future<void> fetchTargetMahasiswa(int mahasiswaId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _targetMahasiswa = await _service.getTargetByMahasiswa(mahasiswaId);
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
      _allTargets = await _service.getAllTargetByDosen(dosenId);
    } catch (e) {
      _allTargets = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> upsertTarget(
      int mahasiswaId, String targetSelesai, int createdBy) async {
    try {
      final result = await _service.upsertTarget(mahasiswaId, targetSelesai, createdBy);
      if (result > 0) {
        _targetMahasiswa = await _service.getTargetByMahasiswa(mahasiswaId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
