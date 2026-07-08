import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/jadwal_model.dart';
import '../models/booking_model.dart';
import '../models/progres_model.dart';
import '../models/validasi_model.dart';
import '../models/konsultasi_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  // === USERS ===
  Future<int> insertUser(UserModel user) async {
    final response = await _client.from('users').insert({
      'nama': user.nama,
      'nim_nip': user.nimNip,
      'email': user.email,
      'password': user.password,
      'role': user.role,
      'jurusan': user.jurusan,
      'foto': user.foto,
    }).select('id').single();
    return (response['id'] as int?) ?? 0;
  }

  Future<UserModel?> getUserById(int id) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return UserModel.fromMap(response);
  }

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

  Future<List<UserModel>> getAllDosen() async {
    final response = await _client
        .from('users')
        .select()
        .eq('role', 'dosen');
    return (response as List).map((m) => UserModel.fromMap(m)).toList();
  }

  Future<List<UserModel>> getAllMahasiswa() async {
    final response = await _client
        .from('users')
        .select()
        .eq('role', 'mahasiswa');
    return (response as List).map((m) => UserModel.fromMap(m)).toList();
  }

  Future<int> updateUser(UserModel user) async {
    await _client
        .from('users')
        .update(user.toMap())
        .eq('id', user.id!);
    return 1;
  }

  Future<int> deleteUser(int id) async {
    await _client.from('users').delete().eq('id', id);
    return 1;
  }

  // === JADWAL DOSEN ===
  Future<int> insertJadwal(JadwalModel jadwal) async {
    final response = await _client.from('jadwal_dosen').insert({
      'dosen_id': jadwal.dosenId,
      'hari': jadwal.hari,
      'tanggal': jadwal.tanggal,
      'jam_mulai': jadwal.jamMulai,
      'jam_selesai': jadwal.jamSelesai,
      'status': jadwal.status,
      'lokasi': jadwal.lokasi,
      'keterangan': jadwal.keterangan,
    }).select('id').single();
    return (response['id'] as int?) ?? 0;
  }

  Future<List<JadwalModel>> getJadwalByDosen(int dosenId) async {
    final response = await _client
        .from('jadwal_dosen')
        .select()
        .eq('dosen_id', dosenId);
    return (response as List).map((m) => JadwalModel.fromMap(m)).toList();
  }

  Future<List<JadwalModel>> getJadwalTersedia(int dosenId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final response = await _client
        .from('jadwal_dosen')
        .select()
        .eq('dosen_id', dosenId)
        .eq('status', 'tersedia')
        .gte('tanggal', today) // hanya jadwal yang belum lewat
        .order('tanggal', ascending: true);
    return (response as List).map((m) => JadwalModel.fromMap(m)).toList();
  }

  Future<JadwalModel?> getJadwalById(int id) async {
    final response = await _client
        .from('jadwal_dosen')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return JadwalModel.fromMap(response);
  }

  Future<List<JadwalModel>> getJadwalByTanggal(int dosenId, String tanggal) async {
    final response = await _client
        .from('jadwal_dosen')
        .select()
        .eq('dosen_id', dosenId)
        .eq('tanggal', tanggal);
    return (response as List).map((m) => JadwalModel.fromMap(m)).toList();
  }

  Future<int> updateStatusJadwal(int id, String status) async {
    await _client
        .from('jadwal_dosen')
        .update({'status': status})
        .eq('id', id);
    return 1;
  }

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
        })
        .eq('id', jadwal.id!);
    return 1;
  }

  Future<int> deleteJadwal(int id) async {
    await _client.from('jadwal_dosen').delete().eq('id', id);
    return 1;
  }

  // === BOOKING ===
  Future<int> insertBooking(BookingModel booking) async {
    final response = await _client.from('booking').insert({
      'mahasiswa_id': booking.mahasiswaId,
      'dosen_id': booking.dosenId,
      'jadwal_id': booking.jadwalId,
      'keperluan': booking.keperluan,
      'status': booking.status,
      'catatan_staf': booking.catatanStaf,
      'created_at': booking.createdAt,
    }).select('id').single();
    return (response['id'] as int?) ?? 0;
  }

  /// Cek apakah mahasiswa sudah booking jadwal tertentu
  Future<List<BookingModel>> getBookingByMahasiswaAndJadwal(int mahasiswaId, int jadwalId) async {
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

  Future<List<BookingModel>> getBookingByMahasiswa(int mahasiswaId) async {
    try {
      final response = await _client
          .from('booking')
          .select()
          .eq('mahasiswa_id', mahasiswaId)
          .order('created_at', ascending: false);
      return (response as List).map((m) => BookingModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<BookingModel>> getBookingByDosen(int dosenId) async {
    try {
      final response = await _client
          .from('booking')
          .select()
          .eq('dosen_id', dosenId)
          .order('created_at', ascending: false);
      return (response as List).map((m) => BookingModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<BookingModel>> getAllBooking() async {
    try {
      final response = await _client
          .from('booking')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((m) => BookingModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<BookingModel?> getBookingById(int id) async {
    try {
      final response = await _client
          .from('booking')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return BookingModel.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<int> updateStatusBooking(int id, String status, String? catatanStaf) async {
    await _client
        .from('booking')
        .update({'status': status, 'catatan_staf': catatanStaf})
        .eq('id', id);
    return 1;
  }

  Future<int> deleteBooking(int id) async {
    await _client.from('booking').delete().eq('id', id);
    return 1;
  }

  // === PROGRES SKRIPSI ===
  Future<int> insertProgres(ProgresModel progres) async {
    final response = await _client.from('progres_skripsi').insert({
      'mahasiswa_id': progres.mahasiswaId,
      'dosen_id': progres.dosenId,
      'judul_skripsi': progres.judulSkripsi,
      'tahap': progres.tahap,
      'status': progres.status,
      'catatan': progres.catatan,
      'catatan_mahasiswa': progres.catatanMahasiswa,
      'updated_at': progres.updatedAt,
    }).select('id').single();
    return (response['id'] as int?) ?? 0;
  }

  Future<List<ProgresModel>> getAllTahapByMahasiswa(int mahasiswaId) async {
    try {
      final response = await _client
          .from('progres_skripsi')
          .select()
          .eq('mahasiswa_id', mahasiswaId)
          .order('id', ascending: true);
      return (response as List).map((m) => ProgresModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<int, List<ProgresModel>>> getAllTahapGroupedByMahasiswaForDosen(int dosenId) async {
    try {
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
      return grouped;
    } catch (e) {
      return {};
    }
  }

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

  Future<int> updateProgres(ProgresModel progres) async {
    await _client.from('progres_skripsi').update({
      'judul_skripsi': progres.judulSkripsi,
      'tahap': progres.tahap,
      'status': progres.status,
      'catatan': progres.catatan,
      'catatan_mahasiswa': progres.catatanMahasiswa,
      'updated_at': progres.updatedAt,
    }).eq('id', progres.id!);
    return 1;
  }

  Future<int> updateStatusProgresById(int id, String status, String? catatan) async {
    try {
      await _client.from('progres_skripsi').update({
        'status': status,
        'catatan': catatan,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return 1;
    } catch (e) {
      return 0;
    }
  }

  Future<int> ajukanKeDosen(int id, String catatanMahasiswa) async {
    try {
      await _client.from('progres_skripsi').update({
        'status': 'menunggu_konfirmasi',
        'catatan_mahasiswa': catatanMahasiswa,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return 1;
    } catch (e) {
      return 0;
    }
  }

  // === VALIDASI KEHADIRAN ===
  Future<int> insertValidasi(ValidasiModel validasi) async {
    final response = await _client.from('validasi_kehadiran').insert({
      'booking_id': validasi.bookingId,
      'dosen_id': validasi.dosenId,
      'mahasiswa_id': validasi.mahasiswaId,
      'status_hadir': validasi.statusHadir,
      'catatan': validasi.catatan,
      'validated_at': validasi.validatedAt,
    }).select('id').single();
    return (response['id'] as int?) ?? 0;
  }

  Future<ValidasiModel?> getValidasiByBooking(int bookingId) async {
    final response = await _client
        .from('validasi_kehadiran')
        .select()
        .eq('booking_id', bookingId)
        .maybeSingle();
    if (response == null) return null;
    return ValidasiModel.fromMap(response);
  }

  Future<int> updateValidasi(int id, String statusHadir, String? catatan) async {
    await _client.from('validasi_kehadiran').update({
      'status_hadir': statusHadir,
      'catatan': catatan,
      'validated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
    return 1;
  }

  // === TARGET BIMBINGAN ===
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

  Future<List<Map<String, dynamic>>> getAllTargetByDosen(int dosenId) async {
    try {
      // Ambil semua mahasiswa_id yang memiliki progres dengan dosen ini
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

  Future<int> upsertTarget(int mahasiswaId, String targetSelesai, int createdBy) async {
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

  // === DOSEN PEMBIMBING MAHASISWA ===
  /// Mengambil dosen_id pembimbing mahasiswa dari tabel progres_skripsi.
  /// Digunakan untuk fitur booking agar mahasiswa hanya bisa booking ke dosennya sendiri.
  Future<int?> getDosenPembimbingByMahasiswa(int mahasiswaId) async {
    try {
      final response = await _client
          .from('progres_skripsi')
          .select('dosen_id')
          .eq('mahasiswa_id', mahasiswaId)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return response['dosen_id'] as int?;
    } catch (e) {
      return null;
    }
  }

  // === PROGRES DIKELOLA MAHASISWA ===
  /// Menambah progres baru oleh mahasiswa
  Future<int> insertProgresByMahasiswa(ProgresModel progres) async {
    try {
      final response = await _client.from('progres_skripsi').insert({
        'mahasiswa_id': progres.mahasiswaId,
        'dosen_id': progres.dosenId,
        'judul_skripsi': progres.judulSkripsi,
        'tahap': progres.tahap,
        'status': progres.status,
        'catatan': progres.catatan,
        'catatan_mahasiswa': progres.catatanMahasiswa,
        'updated_at': DateTime.now().toIso8601String(),
      }).select('id').single();
      return (response['id'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Memperbarui progres oleh mahasiswa (judul, catatan, tahap)
  Future<int> updateProgresByMahasiswa(ProgresModel progres) async {
    try {
      await _client.from('progres_skripsi').update({
        'judul_skripsi': progres.judulSkripsi,
        'tahap': progres.tahap,
        'catatan_mahasiswa': progres.catatanMahasiswa,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', progres.id!);
      return 1;
    } catch (e) {
      return 0;
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

  // === FITUR PENCARIAN DOSEN ===
  Future<List<UserModel>> searchDosen(String keyword) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('role', 'dosen')
          .ilike('nama', '%$keyword%');
      return (response as List).map((m) => UserModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> dosenPunyaJadwal(int dosenId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final response = await _client
          .from('jadwal_dosen')
          .select()
          .eq('dosen_id', dosenId)
          .eq('status', 'tersedia')
          .gte('tanggal', today)
          .limit(1);
      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // === RIWAYAT KONSULTASI ===
  Future<int> insertKonsultasi(KonsultasiModel data) async {
    try {
      final response = await _client.from('riwayat_konsultasi').insert({
        'mahasiswa_id': data.mahasiswaId,
        if (data.dosenId != null) 'dosen_id': data.dosenId,
        'tanggal': data.tanggal,
        'isi_konsultasi': data.isiKonsultasi,
        'status': data.status,
        'created_at': data.createdAt,
      }).select('id').single();
      return (response['id'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<List<KonsultasiModel>> getKonsultasiByMahasiswa(int mahasiswaId) async {
    try {
      final response = await _client
          .from('riwayat_konsultasi')
          .select()
          .eq('mahasiswa_id', mahasiswaId)
          .order('tanggal', ascending: false)
          .order('created_at', ascending: false);
      return (response as List).map((m) => KonsultasiModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> deleteKonsultasi(int id) async {
    try {
      await _client.from('riwayat_konsultasi').delete().eq('id', id);
      return 1;
    } catch (e) {
      return 0;
    }
  }
}


