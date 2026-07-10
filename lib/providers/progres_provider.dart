import 'package:flutter/material.dart';
import '../database/supabase_service.dart';
import '../models/progres_model.dart';

class ProgresProvider with ChangeNotifier {
  List<ProgresModel> _tahapMahasiswa = [];
  Map<int, List<ProgresModel>> _tahapGroupedByMahasiswa = {};
  bool _isLoading = false;
  int _menungguKonfirmasiCount = 0;
  final SupabaseService _service = SupabaseService();

  List<ProgresModel> get tahapMahasiswa => _tahapMahasiswa;
  Map<int, List<ProgresModel>> get tahapGroupedByMahasiswa =>
      _tahapGroupedByMahasiswa;
  bool get isLoading => _isLoading;
  int get menungguKonfirmasiCount => _menungguKonfirmasiCount;

  // ===== MAHASISWA =====

  Future<void> fetchTahapMahasiswa(int mahasiswaId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _tahapMahasiswa = await _service.getAllTahapByMahasiswa(mahasiswaId);
    } catch (e) {
      _tahapMahasiswa = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> ajukanKeDosen(int progresId, String catatanMahasiswa) async {
    try {
      final result = await _service.ajukanKeDosen(progresId, catatanMahasiswa);
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

  Future<void> fetchTahapGroupedByMahasiswaForDosen(int dosenId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _tahapGroupedByMahasiswa = await _service
          .getAllTahapGroupedByMahasiswaForDosen(dosenId);
      _menungguKonfirmasiCount = await _service.countMenungguKonfirmasiByDosen(
        dosenId,
      );
    } catch (e) {
      _tahapGroupedByMahasiswa = {};
      _menungguKonfirmasiCount = 0;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateStatusByDosen(
    int progresId,
    String status,
    String? catatan,
    int dosenId,
  ) async {
    try {
      final result = await _service.updateStatusProgresById(
        progresId,
        status,
        catatan,
      );
      if (result > 0) {
        for (final key in _tahapGroupedByMahasiswa.keys) {
          final list = _tahapGroupedByMahasiswa[key]!;
          final idx = list.indexWhere((p) => p.id == progresId);
          if (idx != -1) {
            list[idx] = list[idx].copyWith(status: status, catatan: catatan);
            break;
          }
        }
        _menungguKonfirmasiCount = await _service
            .countMenungguKonfirmasiByDosen(dosenId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ===== LEGACY =====
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
        result = await _service.updateProgres(progres);
      } else {
        result = await _service.insertProgres(progres);
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

  // ===== FITUR 3: PROGRES DIKELOLA MAHASISWA =====

  /// Menambah progres baru oleh mahasiswa
  Future<bool> tambahProgres(ProgresModel progres) async {
    try {
      final result = await _service.insertProgresByMahasiswa(progres);
      if (result > 0) {
        // Refresh daftar progres mahasiswa setelah berhasil ditambah
        await fetchTahapMahasiswa(progres.mahasiswaId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Mengedit progres oleh mahasiswa (hanya data yang diperbolehkan)
  Future<bool> editProgres(ProgresModel progres) async {
    try {
      final result = await _service.updateProgresByMahasiswa(progres);
      if (result > 0) {
        // Update data lokal di list
        final idx = _tahapMahasiswa.indexWhere((p) => p.id == progres.id);
        if (idx != -1) {
          _tahapMahasiswa[idx] = progres;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Menghapus progres oleh mahasiswa
  Future<bool> hapusProgres(int progresId) async {
    try {
      final result = await _service.deleteProgresByMahasiswa(progresId);
      if (result > 0) {
        // Hapus dari daftar lokal
        _tahapMahasiswa.removeWhere((p) => p.id == progresId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Memperbarui judul skripsi mahasiswa
  Future<bool> updateJudulSkripsi(int mahasiswaId, String newJudul) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _service.updateJudulSkripsi(mahasiswaId, newJudul);
      if (success) {
        // Update local list
        _tahapMahasiswa = _tahapMahasiswa
            .map((p) => p.copyWith(judulSkripsi: newJudul))
            .toList();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
