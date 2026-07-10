import 'package:flutter/material.dart';
import '../database/supabase_service.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';

class BookingProvider with ChangeNotifier {
  List<BookingModel> _bookingList = [];
  bool _isLoading = false;
  String? _error;

  UserModel? _selectedDosenForBooking;
  UserModel? get selectedDosenForBooking => _selectedDosenForBooking;

  void setSelectedDosenForBooking(UserModel? dosen) {
    _selectedDosenForBooking = dosen;
    notifyListeners();
  }

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
    return DateTime.now().difference(_lastFetchedAt!).inSeconds <
        _cacheDurationSeconds;
  }

  void _invalidateCache() {
    _lastFetchedUserId = null;
    _lastFetchedRole = null;
    _lastFetchedAt = null;
  }

  /// Fetch booking milik mahasiswa (dengan cache)
  Future<void> fetchBookingByMahasiswa(
    int mahasiswaId, {
    bool forceRefresh = false,
  }) async {
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
  Future<void> fetchBookingByDosen(
    int dosenId, {
    bool forceRefresh = false,
  }) async {
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
      // Validasi 0: Cek apakah dosen yang dibooking adalah dosen pembimbing mahasiswa
      final assignedDosenId = await _service.getDosenPembimbingByMahasiswa(
        booking.mahasiswaId,
      );
      if (assignedDosenId == null) {
        return 'Anda belum memiliki dosen pembimbing. Silakan hubungi akademik.';
      }
      if (assignedDosenId != booking.dosenId) {
        return 'Anda hanya diizinkan mem-booking jadwal dosen pembimbing Anda sendiri.';
      }

      // Validasi 1: Tanggal tidak boleh sudah lewat (jika tanggal diisi)
      if (booking.tanggal != null && booking.tanggal!.isNotEmpty) {
        try {
          final jadwalDate = DateTime.parse(booking.tanggal!);
          if (jadwalDate.isBefore(
            DateTime.now().subtract(const Duration(days: 1)),
          )) {
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

      // Validasi 3: Cek apakah jadwal masih tersedia
      final jadwal = await _service.getJadwalById(booking.jadwalId);
      if (jadwal == null) {
        return 'Jadwal tidak ditemukan.';
      }

      int totalSlots = jadwal.kuota;

      // Hitung booking aktif saat ini (bukan ditolak)
      final activeBookings = await _service.getBookingByJadwalActive(
        booking.jadwalId,
      );
      if (activeBookings.length >= totalSlots) {
        // Update status jadwal ke penuh di database
        await _service.updateJadwalSisaSlotAndStatus(
          booking.jadwalId,
          0,
          'penuh',
        );
        return 'Maaf, seluruh slot pada jadwal ini telah penuh.';
      }

      // Simpan booking ke database
      final newId = await _service.insertBooking(booking);
      if (newId > 0) {
        // Hitung ulang booking aktif & sisa slot setelah booking baru
        final updatedActive = await _service.getBookingByJadwalActive(
          booking.jadwalId,
        );
        final newSisaSlot = totalSlots - updatedActive.length;
        final newStatus = newSisaSlot <= 0 ? 'penuh' : 'tersedia';
        await _service.updateJadwalSisaSlotAndStatus(
          booking.jadwalId,
          newSisaSlot,
          newStatus,
        );

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
  Future<bool> updateStatusBooking(
    int id,
    String status,
    String? catatan,
  ) async {
    try {
      await _service.updateStatusBooking(id, status, catatan);

      // Update local list
      final idx = _bookingList.indexWhere((b) => b.id == id);
      if (idx != -1) {
        _bookingList[idx] = _bookingList[idx].copyWith(
          status: status,
          catatanStaf: catatan,
        );
      }

      // Recompute sisa slot & status jadwal
      final booking = idx != -1
          ? _bookingList[idx]
          : await _service.getBookingById(id);
      if (booking != null) {
        final jadwal = await _service.getJadwalById(booking.jadwalId);
        if (jadwal != null) {
          final activeBookings = await _service.getBookingByJadwalActive(
            booking.jadwalId,
          );
          final newSisaSlot = jadwal.kuota - activeBookings.length;
          final newStatus = newSisaSlot <= 0 ? 'penuh' : 'tersedia';
          await _service.updateJadwalSisaSlotAndStatus(
            booking.jadwalId,
            newSisaSlot,
            newStatus,
          );
        }
      }

      notifyListeners();
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
