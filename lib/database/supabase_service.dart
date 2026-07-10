import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/jadwal_model.dart';
import '../models/booking_model.dart';
import '../models/progres_model.dart';
import '../models/validasi_model.dart';
import '../models/konsultasi_model.dart';

/// Service utama untuk semua operasi database Supabase.
/// Menggunakan Singleton pattern agar instance hanya satu.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  // ============================================================
  // === USERS ===
  // ============================================================

  /// Insert user baru ke tabel users
  Future<int> insertUser(UserModel user) async {
    final response = await _client
        .from('users')
        .insert({
          'nama': user.nama,
          'nim_nip': user.nimNip,
          'email': user.email,
          'password': user.password,
          'role': user.role,
          'jurusan': user.jurusan,
          'foto': user.foto,
          'nidn': user.nidn,
          'prodi': user.prodi,
          'bidang_keahlian': user.bidangKeahlian,
          'phone': user.phone,
        })
        .select('id')
        .single();
    return (response['id'] as int?) ?? 0;
  }

  /// Ambil user berdasarkan ID
  Future<UserModel?> getUserById(int id) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return UserModel.fromMap(response);
  }

  /// Login menggunakan nim_nip dan password
  Future<UserModel?> login(String nimNip, String password) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('nim_nip', nimNip)
          .eq('password', password)
          .maybeSingle();
      if (response == null) return null;
      return UserModel.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Ambil semua dosen beserta status jadwal mereka
  /// Status: 'tersedia' jika ada jadwal aktif, 'tidak_ada' jika tidak ada
  Future<List<UserModel>> getAllDosen() async {
    final response = await _client
        .from('users')
        .select()
        .eq('role', 'dosen')
        .order('nama', ascending: true);
    return (response as List).map((m) => UserModel.fromMap(m)).toList();
  }

  /// Ambil semua dosen dengan info status jadwal (apakah tersedia)
  Future<List<Map<String, dynamic>>> getAllDosenWithScheduleStatus() async {
    try {
      // Ambil semua dosen
      final dosenList = await _client
          .from('users')
          .select()
          .eq('role', 'dosen')
          .order('nama', ascending: true);

      // Ambil jadwal tersedia hari ini atau ke depan
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final jadwalList = await _client
          .from('jadwal_dosen')
          .select('dosen_id, status')
          .eq('status', 'tersedia')
          .gte('tanggal', today);

      // Buat set dosen yang memiliki jadwal tersedia
      final dosenWithJadwal = <int>{};
      for (final j in (jadwalList as List)) {
        dosenWithJadwal.add(j['dosen_id'] as int);
      }

      // Gabungkan info
      return (dosenList as List).map((d) {
        final result = Map<String, dynamic>.from(d);
        result['has_jadwal'] = dosenWithJadwal.contains(d['id'] as int);
        return result;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Ambil semua mahasiswa
  Future<List<UserModel>> getAllMahasiswa() async {
    final response = await _client
        .from('users')
        .select()
        .eq('role', 'mahasiswa')
        .order('nama', ascending: true);
    return (response as List).map((m) => UserModel.fromMap(m)).toList();
  }

  Future<int> updateUser(UserModel user) async {
    await _client
        .from('users')
        .update({
          'nama': user.nama,
          'email': user.email,
          'jurusan': user.jurusan,
          'foto': user.foto,
          'nidn': user.nidn,
          'prodi': user.prodi,
          'bidang_keahlian': user.bidangKeahlian,
          'phone': user.phone,
        })
        .eq('id', user.id!);
    return 1;
  }

  /// Hapus user berdasarkan ID
  Future<int> deleteUser(int id) async {
    await _client.from('users').delete().eq('id', id);
    return 1;
  }

  // ============================================================
  // === DOSEN PEMBIMBING RELASI ===
  // ============================================================

  /// Mengambil dosen_id pembimbing mahasiswa.
  /// Pertama cek dari tabel dosen_pembimbing (jika ada), fallback ke progres_skripsi.
  Future<int?> getDosenPembimbingByMahasiswa(int mahasiswaId) async {
    try {
      // Coba dari tabel dosen_pembimbing terlebih dahulu
      final response = await _client
          .from('dosen_pembimbing')
          .select('dosen_id')
          .eq('mahasiswa_id', mahasiswaId)
          .maybeSingle();
      if (response != null) return response['dosen_id'] as int?;

      // Fallback: ambil dari progres_skripsi (relasi lama)
      final progresResponse = await _client
          .from('progres_skripsi')
          .select('dosen_id')
          .eq('mahasiswa_id', mahasiswaId)
          .limit(1)
          .maybeSingle();
      if (progresResponse == null) return null;
      return progresResponse['dosen_id'] as int?;
    } catch (e) {
      // Jika tabel dosen_pembimbing belum ada, fallback ke progres_skripsi
      try {
        final progresResponse = await _client
            .from('progres_skripsi')
            .select('dosen_id')
            .eq('mahasiswa_id', mahasiswaId)
            .limit(1)
            .maybeSingle();
        if (progresResponse == null) return null;
        return progresResponse['dosen_id'] as int?;
      } catch (_) {
        return null;
      }
    }
  }

  /// Menetapkan atau mengubah dosen pembimbing mahasiswa.
  /// Upsert ke tabel dosen_pembimbing berdasarkan mahasiswa_id.
  Future<bool> setDosenPembimbing(int mahasiswaId, int dosenId) async {
    try {
      await _client.from('dosen_pembimbing').upsert({
        'mahasiswa_id': mahasiswaId,
        'dosen_id': dosenId,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'mahasiswa_id');
    } catch (_) {
      // Ignore if table doesn't exist
    }

    try {
      final existing = await _client
          .from('progres_skripsi')
          .select('id')
          .eq('mahasiswa_id', mahasiswaId);

      final List list = existing as List;
      if (list.isNotEmpty) {
        await _client
            .from('progres_skripsi')
            .update({
              'dosen_id': dosenId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('mahasiswa_id', mahasiswaId);
      } else {
        final stages = [
          'bab1',
          'bab2',
          'bab3',
          'seminar_proposal',
          'bab4_5',
          'sidang',
          'selesai',
        ];
        for (final stage in stages) {
          await _client.from('progres_skripsi').insert({
            'mahasiswa_id': mahasiswaId,
            'dosen_id': dosenId,
            'tahap': stage,
            'status': 'belum',
            'judul_skripsi': 'Belum ditentukan',
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Ambil semua relasi dosen pembimbing untuk ditampilkan oleh staf
  Future<List<Map<String, dynamic>>> getAllDosenPembimbingRelasi() async {
    try {
      final response = await _client
          .from('dosen_pembimbing')
          .select(
            '*, mahasiswa:mahasiswa_id(nama, nim_nip), dosen:dosen_id(nama, nim_nip)',
          );
      final list = (response as List)
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      if (list.isNotEmpty) return list;

      // Fallback ke progres_skripsi jika dosen_pembimbing kosong
      final fallbackResponse = await _client
          .from('progres_skripsi')
          .select(
            'mahasiswa_id, dosen_id, mahasiswa:mahasiswa_id(nama, nim_nip), dosen:dosen_id(nama, nim_nip)',
          );
      final fbList = (fallbackResponse as List)
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      final seen = <int>{};
      final uniqueList = <Map<String, dynamic>>[];
      for (final item in fbList) {
        final mId = item['mahasiswa_id'] as int?;
        if (mId != null && !seen.contains(mId)) {
          seen.add(mId);
          uniqueList.add(item);
        }
      }
      return uniqueList;
    } catch (e) {
      try {
        final fallbackResponse = await _client
            .from('progres_skripsi')
            .select(
              'mahasiswa_id, dosen_id, mahasiswa:mahasiswa_id(nama, nim_nip), dosen:dosen_id(nama, nim_nip)',
            );
        final fbList = (fallbackResponse as List)
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        final seen = <int>{};
        final uniqueList = <Map<String, dynamic>>[];
        for (final item in fbList) {
          final mId = item['mahasiswa_id'] as int?;
          if (mId != null && !seen.contains(mId)) {
            seen.add(mId);
            uniqueList.add(item);
          }
        }
        return uniqueList;
      } catch (_) {}
      return [];
    }
  }

  /// Ambil semua mahasiswa bimbingan milik seorang dosen
  Future<List<UserModel>> getMahasiswaByDosen(int dosenId) async {
    try {
      final response = await _client
          .from('dosen_pembimbing')
          .select('mahasiswa_id, mahasiswa:mahasiswa_id(*)')
          .eq('dosen_id', dosenId);

      final result = <UserModel>[];
      for (final item in (response as List)) {
        if (item['mahasiswa'] != null) {
          result.add(
            UserModel.fromMap(item['mahasiswa'] as Map<String, dynamic>),
          );
        }
      }
      if (result.isNotEmpty) return result;

      // Fallback ke progres_skripsi
      final fallbackResponse = await _client
          .from('progres_skripsi')
          .select('mahasiswa_id, mahasiswa:mahasiswa_id(*)')
          .eq('dosen_id', dosenId);

      final seen = <int>{};
      for (final item in (fallbackResponse as List)) {
        if (item['mahasiswa'] != null) {
          final student = UserModel.fromMap(
            item['mahasiswa'] as Map<String, dynamic>,
          );
          if (!seen.contains(student.id)) {
            seen.add(student.id!);
            result.add(student);
          }
        }
      }
      return result;
    } catch (e) {
      return [];
    }
  }

  /// Hitung jumlah mahasiswa bimbingan milik seorang dosen
  Future<int> getMahasiswaBimbinganCount(int dosenId) async {
    try {
      final response = await _client
          .from('dosen_pembimbing')
          .select('id')
          .eq('dosen_id', dosenId);
      final count = (response as List).length;
      if (count > 0) return count;

      // Fallback ke progres_skripsi
      final fallbackResponse = await _client
          .from('progres_skripsi')
          .select('mahasiswa_id')
          .eq('dosen_id', dosenId);
      final list = fallbackResponse as List;
      final seen = <int>{};
      for (final item in list) {
        final mId = item['mahasiswa_id'] as int?;
        if (mId != null) seen.add(mId);
      }
      return seen.length;
    } catch (e) {
      return 0;
    }
  }

  // ============================================================
  // === JADWAL DOSEN ===
  // ============================================================

  /// Insert jadwal baru
  Future<int> insertJadwal(JadwalModel jadwal) async {
    final response = await _client
        .from('jadwal_dosen')
        .insert({
          'dosen_id': jadwal.dosenId,
          'hari': jadwal.hari,
          'tanggal': jadwal.tanggal,
          'jam_mulai': jadwal.jamMulai,
          'jam_selesai': jadwal.jamSelesai,
          'status': jadwal.status,
          'lokasi': jadwal.lokasi,
          'keterangan': jadwal.keterangan,
          'kuota': jadwal.kuota,
          'sisa_slot': jadwal.sisaSlot,
        })
        .select('id')
        .single();
    return (response['id'] as int?) ?? 0;
  }

  /// Ambil jadwal milik dosen tertentu
  Future<List<JadwalModel>> getJadwalByDosen(int dosenId) async {
    final response = await _client
        .from('jadwal_dosen')
        .select()
        .eq('dosen_id', dosenId)
        .order('id', ascending: true);
    return (response as List).map((m) => JadwalModel.fromMap(m)).toList();
  }

  /// Ambil jadwal dosen yang masih tersedia (belum lewat dan status 'tersedia')
  Future<List<JadwalModel>> getJadwalTersedia(int dosenId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final response = await _client
        .from('jadwal_dosen')
        .select()
        .eq('dosen_id', dosenId)
        .eq('status', 'tersedia')
        .or(
          'tanggal.is.null,tanggal.gte.$today',
        ) // mendukung jadwal rutin (tanggal null) & terjadwal
        .order('id', ascending: true);
    return (response as List).map((m) => JadwalModel.fromMap(m)).toList();
  }

  /// Ambil jadwal berdasarkan ID
  Future<JadwalModel?> getJadwalById(int id) async {
    final response = await _client
        .from('jadwal_dosen')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return JadwalModel.fromMap(response);
  }

  /// Ambil jadwal berdasarkan tanggal dan dosen
  Future<List<JadwalModel>> getJadwalByTanggal(
    int dosenId,
    String tanggal,
  ) async {
    final response = await _client
        .from('jadwal_dosen')
        .select()
        .eq('dosen_id', dosenId)
        .eq('tanggal', tanggal);
    return (response as List).map((m) => JadwalModel.fromMap(m)).toList();
  }

  /// Update status jadwal (tersedia/penuh)
  Future<int> updateStatusJadwal(int id, String status) async {
    await _client.from('jadwal_dosen').update({'status': status}).eq('id', id);
    return 1;
  }

  /// Update sisa slot dan status jadwal
  Future<int> updateJadwalSisaSlotAndStatus(
    int id,
    int sisaSlot,
    String status,
  ) async {
    await _client
        .from('jadwal_dosen')
        .update({'sisa_slot': sisaSlot, 'status': status})
        .eq('id', id);
    return 1;
  }

  /// Update jadwal dosen secara lengkap
  Future<int> updateJadwal(JadwalModel jadwal) async {
    await _client
        .from('jadwal_dosen')
        .update({
          'hari': jadwal.hari,
          'tanggal': jadwal.tanggal,
          'jam_mulai': jadwal.jamMulai,
          'jam_selesai': jadwal.jamSelesai,
          'status': jadwal.status,
          'lokasi': jadwal.lokasi,
          'keterangan': jadwal.keterangan,
          'kuota': jadwal.kuota,
          'sisa_slot': jadwal.sisaSlot,
        })
        .eq('id', jadwal.id!);
    return 1;
  }

  /// Hapus jadwal
  Future<int> deleteJadwal(int id) async {
    await _client.from('jadwal_dosen').delete().eq('id', id);
    return 1;
  }

  // ============================================================
  // === BOOKING ===
  // ============================================================

  /// Insert booking baru
  Future<int> insertBooking(BookingModel booking) async {
    final response = await _client
        .from('booking')
        .insert({
          'mahasiswa_id': booking.mahasiswaId,
          'dosen_id': booking.dosenId,
          'jadwal_id': booking.jadwalId,
          'keperluan': booking.keperluan,
          'status': booking.status,
          'catatan_staf': booking.catatanStaf,
          'created_at': booking.createdAt,
        })
        .select('id')
        .single();
    return (response['id'] as int?) ?? 0;
  }

  /// Cek apakah mahasiswa sudah booking jadwal tertentu (exclude rejected)
  Future<List<BookingModel>> getBookingByMahasiswaAndJadwal(
    int mahasiswaId,
    int jadwalId,
  ) async {
    try {
      final response = await _client
          .from('booking')
          .select()
          .eq('mahasiswa_id', mahasiswaId)
          .eq('jadwal_id', jadwalId)
          .neq('status', 'rejected'); // exclude yang sudah ditolak
      return (response as List).map((m) => BookingModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Ambil semua booking milik mahasiswa
  Future<List<BookingModel>> getBookingByMahasiswa(int mahasiswaId) async {
    try {
      final response = await _client
          .from('booking')
          .select(
            '*, users!booking_mahasiswa_id_fkey(nama, nim_nip), dosen:dosen_id(nama, foto), jadwal_dosen!booking_jadwal_id_fkey(tanggal, jam_mulai, jam_selesai, hari)',
          )
          .eq('mahasiswa_id', mahasiswaId)
          .order('created_at', ascending: false);
      return (response as List).map((m) => BookingModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Ambil booking aktif milik mahasiswa (status approved/pending dan tanggal >= hari ini)
  Future<BookingModel?> getActiveBookingForMahasiswa(int mahasiswaId) async {
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final response = await _client
          .from('booking')
          .select(
            '*, users!booking_mahasiswa_id_fkey(nama, nim_nip), dosen:dosen_id(nama, foto), jadwal_dosen!booking_jadwal_id_fkey(tanggal, jam_mulai, jam_selesai, hari)',
          )
          .eq('mahasiswa_id', mahasiswaId)
          .order('created_at', ascending: false);

      final list = response as List;
      for (final item in list) {
        final b = BookingModel.fromMap(item);
        if (b.status == 'approved' || b.status == 'pending') {
          if (b.tanggal != null && b.tanggal!.isNotEmpty) {
            if (b.tanggal!.compareTo(todayStr) >= 0) {
              return b;
            }
          } else {
            return b; // Jika tidak ada tanggal, anggap aktif
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Ambil semua booking untuk dosen tertentu
  Future<List<BookingModel>> getBookingByDosen(int dosenId) async {
    try {
      final response = await _client
          .from('booking')
          .select(
            '*, users!booking_mahasiswa_id_fkey(nama, nim_nip), dosen:dosen_id(nama, foto), jadwal_dosen!booking_jadwal_id_fkey(tanggal, jam_mulai, jam_selesai, hari)',
          )
          .eq('dosen_id', dosenId)
          .order('created_at', ascending: false);
      return (response as List).map((m) => BookingModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Ambil semua booking (untuk staf/admin)
  Future<List<BookingModel>> getAllBooking() async {
    try {
      final response = await _client
          .from('booking')
          .select(
            '*, users!booking_mahasiswa_id_fkey(nama, nim_nip), dosen:dosen_id(nama, foto), jadwal_dosen!booking_jadwal_id_fkey(tanggal, jam_mulai, jam_selesai, hari)',
          )
          .order('created_at', ascending: false);
      return (response as List).map((m) => BookingModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Ambil booking aktif (bukan ditolak) untuk jadwal tertentu
  Future<List<BookingModel>> getBookingByJadwalActive(int jadwalId) async {
    try {
      final response = await _client
          .from('booking')
          .select()
          .eq('jadwal_id', jadwalId)
          .neq('status', 'rejected')
          .order('created_at', ascending: true);
      return (response as List).map((m) => BookingModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Ambil semua jadwal dosen beserta nama dosennya (untuk monitoring)
  Future<List<Map<String, dynamic>>> getMonitoringJadwal() async {
    try {
      final response = await _client
          .from('jadwal_dosen')
          .select('*, dosen:dosen_id(nama, nim_nip, foto)')
          .order('tanggal', ascending: true);
      return (response as List)
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Ambil semua booking beserta data mahasiswa dan dosen (untuk monitoring)
  Future<List<Map<String, dynamic>>> getMonitoringBookings() async {
    try {
      final response = await _client
          .from('booking')
          .select(
            '*, mahasiswa:mahasiswa_id(nama, nim_nip), dosen:dosen_id(nama)',
          )
          .order('created_at', ascending: true);
      return (response as List)
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Ambil booking berdasarkan ID
  Future<BookingModel?> getBookingById(int id) async {
    try {
      final response = await _client
          .from('booking')
          .select(
            '*, users!booking_mahasiswa_id_fkey(nama, nim_nip), dosen:dosen_id(nama, foto), jadwal_dosen!booking_jadwal_id_fkey(tanggal, jam_mulai, jam_selesai, hari)',
          )
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return BookingModel.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Update status booking (approved/rejected) beserta catatan
  Future<int> updateStatusBooking(
    int id,
    String status,
    String? catatanStaf,
  ) async {
    await _client
        .from('booking')
        .update({'status': status, 'catatan_staf': catatanStaf})
        .eq('id', id);
    return 1;
  }

  /// Hapus booking
  Future<int> deleteBooking(int id) async {
    await _client.from('booking').delete().eq('id', id);
    return 1;
  }

  // ============================================================
  // === PROGRES SKRIPSI ===
  // ============================================================

  /// Insert progres baru
  Future<int> insertProgres(ProgresModel progres) async {
    final response = await _client
        .from('progres_skripsi')
        .insert({
          'mahasiswa_id': progres.mahasiswaId,
          'dosen_id': progres.dosenId,
          'judul_skripsi': progres.judulSkripsi,
          'tahap': progres.tahap,
          'status': progres.status,
          'catatan': progres.catatan,
          'catatan_mahasiswa': progres.catatanMahasiswa,
          'updated_at': progres.updatedAt,
        })
        .select('id')
        .single();
    return (response['id'] as int?) ?? 0;
  }

  /// Ambil semua progres milik mahasiswa
  Future<List<ProgresModel>> getAllTahapByMahasiswa(int mahasiswaId) async {
    try {
      final response = await _client
          .from('progres_skripsi')
          .select()
          .eq('mahasiswa_id', mahasiswaId)
          .order('id', ascending: true);

      final list = (response as List)
          .map((m) => ProgresModel.fromMap(m))
          .toList();
      if (list.isNotEmpty) return list;

      // Jika kosong, inisialisasi jika ada relasi pembimbing
      final dosenId = await getDosenPembimbingByMahasiswa(mahasiswaId);
      if (dosenId != null) {
        final stages = [
          'bab1',
          'bab2',
          'bab3',
          'seminar_proposal',
          'bab4_5',
          'sidang',
          'selesai',
        ];
        final List<ProgresModel> newList = [];
        for (final stage in stages) {
          final insertRes = await _client
              .from('progres_skripsi')
              .insert({
                'mahasiswa_id': mahasiswaId,
                'dosen_id': dosenId,
                'tahap': stage,
                'status': 'belum',
                'judul_skripsi': 'Belum ditentukan',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();
          newList.add(ProgresModel.fromMap(insertRes));
        }
        return newList;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Ambil progres semua mahasiswa bimbingan seorang dosen (dikelompokkan)
  Future<Map<int, List<ProgresModel>>> getAllTahapGroupedByMahasiswaForDosen(
    int dosenId,
  ) async {
    try {
      // 1. Ambil semua mahasiswa bimbingan dari dosen_pembimbing
      final bimbinganStudents = await getMahasiswaByDosen(dosenId);

      // 2. Ambil progres dari progres_skripsi
      final response = await _client
          .from('progres_skripsi')
          .select('*, users!progres_skripsi_mahasiswa_id_fkey(nama)')
          .eq('dosen_id', dosenId)
          .order('mahasiswa_id', ascending: true)
          .order('id', ascending: true);

      final Map<int, List<ProgresModel>> grouped = {};
      for (final map in (response as List)) {
        final enriched = Map<String, dynamic>.from(map);
        if (map['users'] != null) {
          enriched['nama_mahasiswa'] = map['users']['nama'];
        }
        final progres = ProgresModel.fromMap(enriched);
        grouped.putIfAbsent(progres.mahasiswaId, () => []);
        grouped[progres.mahasiswaId]!.add(progres);
      }

      // 3. Self-healing: Inisialisasi/update progres_skripsi untuk mahasiswa bimbingan yang belum ada datanya
      final stages = [
        'bab1',
        'bab2',
        'bab3',
        'seminar_proposal',
        'bab4_5',
        'sidang',
        'selesai',
      ];

      for (final student in bimbinganStudents) {
        if (!grouped.containsKey(student.id)) {
          final existing = await _client
              .from('progres_skripsi')
              .select()
              .eq('mahasiswa_id', student.id!);

          final List existingList = existing as List;
          if (existingList.isNotEmpty) {
            await _client
                .from('progres_skripsi')
                .update({
                  'dosen_id': dosenId,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('mahasiswa_id', student.id!);

            final updatedResponse = await _client
                .from('progres_skripsi')
                .select('*, users!progres_skripsi_mahasiswa_id_fkey(nama)')
                .eq('mahasiswa_id', student.id!)
                .order('id', ascending: true);

            final List<ProgresModel> list = [];
            for (final map in (updatedResponse as List)) {
              final enriched = Map<String, dynamic>.from(map);
              if (map['users'] != null) {
                enriched['nama_mahasiswa'] = map['users']['nama'];
              }
              list.add(ProgresModel.fromMap(enriched));
            }
            grouped[student.id!] = list;
          } else {
            final List<ProgresModel> list = [];
            for (final stage in stages) {
              final insertRes = await _client
                  .from('progres_skripsi')
                  .insert({
                    'mahasiswa_id': student.id!,
                    'dosen_id': dosenId,
                    'tahap': stage,
                    'status': 'belum',
                    'judul_skripsi': 'Belum ditentukan',
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .select('*, users:mahasiswa_id(nama)')
                  .single();

              final enriched = Map<String, dynamic>.from(insertRes);
              if (insertRes['users'] != null) {
                enriched['nama_mahasiswa'] = insertRes['users']['nama'];
              }
              list.add(ProgresModel.fromMap(enriched));
            }
            grouped[student.id!] = list;
          }
        }
      }
      return grouped;
    } catch (e) {
      return {};
    }
  }

  /// Hitung jumlah progres menunggu konfirmasi milik dosen
  Future<int> countMenungguKonfirmasiByDosen(int dosenId) async {
    try {
      final response = await _client
          .from('progres_skripsi')
          .select()
          .eq('dosen_id', dosenId)
          .eq('status', 'menunggu_konfirmasi');
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Update progres secara lengkap
  Future<int> updateProgres(ProgresModel progres) async {
    await _client
        .from('progres_skripsi')
        .update({
          'judul_skripsi': progres.judulSkripsi,
          'tahap': progres.tahap,
          'status': progres.status,
          'catatan': progres.catatan,
          'catatan_mahasiswa': progres.catatanMahasiswa,
          'updated_at': progres.updatedAt,
        })
        .eq('id', progres.id!);
    return 1;
  }

  /// Update status progres (oleh dosen: acc/revisi)
  Future<int> updateStatusProgresById(
    int id,
    String status,
    String? catatan,
  ) async {
    try {
      await _client
          .from('progres_skripsi')
          .update({
            'status': status,
            'catatan': catatan,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return 1;
    } catch (e) {
      return 0;
    }
  }

  /// Mahasiswa mengajukan progres ke dosen (status: menunggu_konfirmasi)
  Future<int> ajukanKeDosen(int id, String catatanMahasiswa) async {
    try {
      await _client
          .from('progres_skripsi')
          .update({
            'status': 'menunggu_konfirmasi',
            'catatan_mahasiswa': catatanMahasiswa,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return 1;
    } catch (e) {
      return 0;
    }
  }

  // === PROGRES DIKELOLA MAHASISWA ===

  /// Menambah progres baru oleh mahasiswa
  Future<int> insertProgresByMahasiswa(ProgresModel progres) async {
    try {
      final response = await _client
          .from('progres_skripsi')
          .insert({
            'mahasiswa_id': progres.mahasiswaId,
            'dosen_id': progres.dosenId,
            'judul_skripsi': progres.judulSkripsi,
            'tahap': progres.tahap,
            'status': progres.status,
            'catatan': progres.catatan,
            'catatan_mahasiswa': progres.catatanMahasiswa,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();
      return (response['id'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Memperbarui progres oleh mahasiswa (judul, catatan, tahap)
  Future<int> updateProgresByMahasiswa(ProgresModel progres) async {
    try {
      await _client
          .from('progres_skripsi')
          .update({
            'judul_skripsi': progres.judulSkripsi,
            'tahap': progres.tahap,
            'catatan_mahasiswa': progres.catatanMahasiswa,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', progres.id!);
      return 1;
    } catch (e) {
      return 0;
    }
  }

  /// Memperbarui judul skripsi mahasiswa untuk seluruh tahapan progresnya
  Future<bool> updateJudulSkripsi(int mahasiswaId, String newJudul) async {
    try {
      await _client
          .from('progres_skripsi')
          .update({
            'judul_skripsi': newJudul,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('mahasiswa_id', mahasiswaId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Menghapus progres oleh mahasiswa
  Future<int> deleteProgresByMahasiswa(int id) async {
    try {
      await _client.from('progres_skripsi').delete().eq('id', id);
      return 1;
    } catch (e) {
      return 0;
    }
  }

  // ============================================================
  // === VALIDASI KEHADIRAN ===
  // ============================================================

  /// Insert data validasi kehadiran
  Future<int> insertValidasi(ValidasiModel validasi) async {
    final response = await _client
        .from('validasi_kehadiran')
        .insert({
          'booking_id': validasi.bookingId,
          'dosen_id': validasi.dosenId,
          'mahasiswa_id': validasi.mahasiswaId,
          'status_hadir': validasi.statusHadir,
          'catatan': validasi.catatan,
          'validated_at': validasi.validatedAt,
        })
        .select('id')
        .single();
    return (response['id'] as int?) ?? 0;
  }

  /// Ambil validasi berdasarkan booking_id
  Future<ValidasiModel?> getValidasiByBooking(int bookingId) async {
    final response = await _client
        .from('validasi_kehadiran')
        .select()
        .eq('booking_id', bookingId)
        .maybeSingle();
    if (response == null) return null;
    return ValidasiModel.fromMap(response);
  }

  /// Update data validasi
  Future<int> updateValidasi(
    int id,
    String statusHadir,
    String? catatan,
  ) async {
    await _client
        .from('validasi_kehadiran')
        .update({
          'status_hadir': statusHadir,
          'catatan': catatan,
          'validated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
    return 1;
  }

  // ============================================================
  // === TARGET BIMBINGAN (dipertahankan untuk backward compat) ===
  // ============================================================

  /// Ambil target bimbingan mahasiswa
  Future<Map<String, dynamic>?> getTargetByMahasiswa(int mahasiswaId) async {
    try {
      final response = await _client
          .from('target_bimbingan')
          .select()
          .eq('mahasiswa_id', mahasiswaId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Ambil semua target untuk dosen
  Future<List<Map<String, dynamic>>> getAllTargetByDosen(int dosenId) async {
    try {
      final progresResponse = await _client
          .from('progres_skripsi')
          .select('mahasiswa_id')
          .eq('dosen_id', dosenId);

      final mahasiswaIds = (progresResponse as List)
          .map((m) => m['mahasiswa_id'] as int)
          .toSet()
          .toList();

      if (mahasiswaIds.isEmpty) return [];

      final response = await _client
          .from('target_bimbingan')
          .select('*, users!target_bimbingan_mahasiswa_id_fkey(nama, nim_nip)')
          .inFilter('mahasiswa_id', mahasiswaIds);

      return (response as List).map((m) {
        final result = Map<String, dynamic>.from(m);
        if (m['users'] != null) {
          result['nama_mahasiswa'] = m['users']['nama'];
          result['nim_nip'] = m['users']['nim_nip'];
        }
        return result;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Upsert target bimbingan mahasiswa
  Future<int> upsertTarget(
    int mahasiswaId,
    String targetSelesai,
    int createdBy,
  ) async {
    try {
      await _client.from('target_bimbingan').upsert({
        'mahasiswa_id': mahasiswaId,
        'target_selesai': targetSelesai,
        'created_by': createdBy,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'mahasiswa_id');
      return 1;
    } catch (e) {
      return 0;
    }
  }

  // ============================================================
  // === KONSULTASI / RIWAYAT BIMBINGAN ===
  // ============================================================

  /// Ambil semua riwayat konsultasi milik mahasiswa (sebagai logbook)
  Future<List<KonsultasiModel>> getKonsultasiByMahasiswa(
    int mahasiswaId,
  ) async {
    try {
      final response = await _client
          .from('riwayat_konsultasi')
          .select()
          .eq('mahasiswa_id', mahasiswaId)
          .order('tanggal', ascending: false);
      return (response as List).map((m) => KonsultasiModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Insert riwayat konsultasi baru
  Future<int> insertKonsultasi(KonsultasiModel konsultasi) async {
    try {
      final response = await _client
          .from('riwayat_konsultasi')
          .insert({
            'mahasiswa_id': konsultasi.mahasiswaId,
            'dosen_id': konsultasi.dosenId,
            'tanggal': konsultasi.tanggal,
            'isi_konsultasi': konsultasi.isiKonsultasi,
            'status': konsultasi.status,
            'created_at': konsultasi.createdAt,
          })
          .select('id')
          .single();
      return (response['id'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Update riwayat konsultasi
  Future<int> updateKonsultasi(KonsultasiModel konsultasi) async {
    try {
      await _client
          .from('riwayat_konsultasi')
          .update({
            'tanggal': konsultasi.tanggal,
            'isi_konsultasi': konsultasi.isiKonsultasi,
            'status': konsultasi.status,
          })
          .eq('id', konsultasi.id!);
      return 1;
    } catch (e) {
      return 0;
    }
  }

  /// Hapus riwayat konsultasi berdasarkan ID
  Future<int> deleteKonsultasi(int id) async {
    try {
      await _client.from('riwayat_konsultasi').delete().eq('id', id);
      return 1;
    } catch (e) {
      return 0;
    }
  }
}
