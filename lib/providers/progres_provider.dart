import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/progres_model.dart';

class ProgresProvider with ChangeNotifier {
  List<ProgresModel> _tahapMahasiswa = [];
  Map<int, List<ProgresModel>> _tahapGroupedByMahasiswa = {};
  bool _isLoading = false;
  int _menungguKonfirmasiCount = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<ProgresModel> get tahapMahasiswa => _tahapMahasiswa;
  Map<int, List<ProgresModel>> get tahapGroupedByMahasiswa =>
      _tahapGroupedByMahasiswa;
  bool get isLoading => _isLoading;
  int get menungguKonfirmasiCount => _menungguKonfirmasiCount;

  // ===== MAHASISWA =====

  /// Ambil semua tahap progres untuk satu mahasiswa
  Future<void> fetchTahapMahasiswa(int mahasiswaId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _tahapMahasiswa = await _dbHelper.getAllTahapByMahasiswa(mahasiswaId);
    } catch (e) {
      _tahapMahasiswa = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Mahasiswa upload bukti revisi dan ajukan ke dosen
  Future<bool> ajukanKeDosen(int progresId, String catatanMahasiswa) async {
    try {
      final result = await _dbHelper.ajukanKeDosen(progresId, catatanMahasiswa);
      if (result > 0) {
        final idx = _tahapMahasiswa.indexWhere((p) => p.id == progresId);
        if (idx != -1) {
          _tahapMahasiswa[idx] = _tahapMahasiswa[idx].copyWith(
            status: 'menunggu_konfirmasi',
            catatanMahasiswa: catatanMahasiswa,
          );
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ===== DOSEN =====

  /// Ambil semua tahap per mahasiswa (digroup) untuk dosen
  Future<void> fetchTahapGroupedByMahasiswaForDosen(int dosenId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _tahapGroupedByMahasiswa =
          await _dbHelper.getAllTahapGroupedByMahasiswaForDosen(dosenId);
      _menungguKonfirmasiCount =
          await _dbHelper.countMenungguKonfirmasiByDosen(dosenId);
    } catch (e) {
      _tahapGroupedByMahasiswa = {};
      _menungguKonfirmasiCount = 0;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Dosen ACC atau kembalikan Revisi
  Future<bool> updateStatusByDosen(
      int progresId, String status, String? catatan, int dosenId) async {
    try {
      final result =
          await _dbHelper.updateStatusProgresById(progresId, status, catatan);
      if (result > 0) {
        // Update in grouped map
        for (final key in _tahapGroupedByMahasiswa.keys) {
          final list = _tahapGroupedByMahasiswa[key]!;
          final idx = list.indexWhere((p) => p.id == progresId);
          if (idx != -1) {
            list[idx] = list[idx].copyWith(
              status: status,
              catatan: catatan,
            );
            break;
          }
        }
        _menungguKonfirmasiCount =
            await _dbHelper.countMenungguKonfirmasiByDosen(dosenId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ===== LEGACY (backward compat) =====
  Future<void> fetchProgresMahasiswa(int mahasiswaId) async {
    await fetchTahapMahasiswa(mahasiswaId);
  }

  Future<void> fetchAllProgresByDosen(int dosenId) async {
    await fetchTahapGroupedByMahasiswaForDosen(dosenId);
  }

  Future<bool> updateProgres(ProgresModel progres) async {
    try {
      int result;
      if (progres.id != null) {
        result = await _dbHelper.updateProgres(progres);
      } else {
        result = await _dbHelper.insertProgres(progres);
      }

      if (result > 0) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
