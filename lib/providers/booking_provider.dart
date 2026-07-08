import 'package:flutter/material.dart';
import '../database/supabase_service.dart';
import '../models/booking_model.dart';

class BookingProvider with ChangeNotifier {
  List<BookingModel> _bookingList = [];
  bool _isLoading = false;
  String? _error;

  // Cache control - avoid redundant fetches
  int? _lastFetchedUserId;
  String? _lastFetchedRole; // 'mahasiswa' | 'dosen'
  DateTime? _lastFetchedAt;
  static const _cacheDurationSeconds = 30;

  final SupabaseService _service = SupabaseService();

  List<BookingModel> get bookingList => _bookingList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Cek apakah cache masih valid
  bool _isCacheValid(int userId, String role) {
    if (_lastFetchedUserId != userId || _lastFetchedRole != role) return false;
    if (_lastFetchedAt == null) return false;
    return DateTime.now().difference(_lastFetchedAt!).inSeconds < _cacheDurationSeconds;
  }

  void _invalidateCache() {
    _lastFetchedUserId = null;
    _lastFetchedRole = null;
    _lastFetchedAt = null;
  }

  /// Fetch booking milik mahasiswa (dengan cache)
  Future<void> fetchBookingByMahasiswa(int mahasiswaId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(mahasiswaId, 'mahasiswa')) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bookingList = await _service.getBookingByMahasiswa(mahasiswaId);
      _lastFetchedUserId = mahasiswaId;
      _lastFetchedRole = 'mahasiswa';
      _lastFetchedAt = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch booking untuk dosen (dengan cache)
  Future<void> fetchBookingByDosen(int dosenId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(dosenId, 'dosen')) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bookingList = await _service.getBookingByDosen(dosenId);
      _lastFetchedUserId = dosenId;
      _lastFetchedRole = 'dosen';
      _lastFetchedAt = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllBooking() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _bookingList = await _service.getAllBooking();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Buat booking baru dengan validasi lengkap
  /// Return: null jika sukses, String pesan error jika gagal
  Future<String?> createBooking(BookingModel booking) async {
    try {
      // Validasi 1: Tanggal tidak boleh sudah lewat
      if (booking.tanggal != null) {
        try {
          final jadwalDate = DateTime.parse(booking.tanggal!);
          if (jadwalDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
            return 'Jadwal ini sudah lewat, tidak dapat dibooking.';
          }
        } catch (_) {}
      }

      // Validasi 2: Cek apakah mahasiswa sudah booking jadwal yang sama
      final existingBookings = await _service.getBookingByMahasiswaAndJadwal(
        booking.mahasiswaId,
        booking.jadwalId,
      );
      if (existingBookings.isNotEmpty) {
        return 'Anda sudah melakukan booking untuk jadwal ini.';
      }

      // Validasi 3: Cek apakah jadwal masih tersedia (status 'tersedia')
      final jadwal = await _service.getJadwalById(booking.jadwalId);
      if (jadwal == null) {
        return 'Jadwal tidak ditemukan.';
      }
      if (jadwal.status == 'penuh') {
        return 'Jadwal ini sudah penuh.';
      }

      // Simpan booking ke database
      final newId = await _service.insertBooking(booking);
      if (newId > 0) {
        // Update status jadwal menjadi 'penuh'
        await _service.updateStatusJadwal(booking.jadwalId, 'penuh');

        // Tambahkan ke local list & invalidate cache
        _invalidateCache();
        notifyListeners();
        return null; // sukses
      }
      return 'Gagal menyimpan booking. Coba lagi.';
    } catch (e) {
      return 'Terjadi kesalahan: ${e.toString()}';
    }
  }

  /// Update status booking (approved/rejected) oleh dosen
  Future<bool> updateStatusBooking(int id, String status, String? catatan) async {
    try {
      await _service.updateStatusBooking(id, status, catatan);

      // Update local list
      final idx = _bookingList.indexWhere((b) => b.id == id);
      if (idx != -1) {
        _bookingList[idx] = _bookingList[idx].copyWith(
          status: status,
          catatanStaf: catatan,
        );
        notifyListeners();
      }

      // Jika rejected, kembalikan jadwal ke status tersedia
      if (status == 'rejected') {
        final booking = idx != -1 ? _bookingList[idx] : await _service.getBookingById(id);
        if (booking != null) {
          await _service.updateStatusJadwal(booking.jadwalId, 'tersedia');
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  void clearBookings() {
    _bookingList = [];
    _invalidateCache();
    notifyListeners();
  }
}
