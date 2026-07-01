import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/jadwal_model.dart';
import '../models/booking_model.dart';
import '../models/progres_model.dart';
import '../models/validasi_model.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bimbingin.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add target_bimbingan table if upgrading from v1
      await db.execute('''
        CREATE TABLE IF NOT EXISTS target_bimbingan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mahasiswa_id INTEGER NOT NULL UNIQUE,
          target_selesai TEXT NOT NULL,
          created_by INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (mahasiswa_id) REFERENCES users(id),
          FOREIGN KEY (created_by) REFERENCES users(id)
        )
      ''');

      // Add catatan_mahasiswa and status menunggu_konfirmasi support
      // Alter progres_skripsi to add catatan_mahasiswa column
      try {
        await db.execute(
            'ALTER TABLE progres_skripsi ADD COLUMN catatan_mahasiswa TEXT');
      } catch (_) {}

      // Seed target for existing mahasiswa
      await _seedTargetBimbingan(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        nim_nip TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        jurusan TEXT NOT NULL,
        foto TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE jadwal_dosen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dosen_id INTEGER NOT NULL,
        hari TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        jam_mulai TEXT NOT NULL,
        jam_selesai TEXT NOT NULL,
        status TEXT DEFAULT 'tersedia',
        lokasi TEXT NOT NULL,
        keterangan TEXT,
        FOREIGN KEY (dosen_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE booking (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mahasiswa_id INTEGER NOT NULL,
        dosen_id INTEGER NOT NULL,
        jadwal_id INTEGER NOT NULL,
        keperluan TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        catatan_staf TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (mahasiswa_id) REFERENCES users(id),
        FOREIGN KEY (dosen_id) REFERENCES users(id),
        FOREIGN KEY (jadwal_id) REFERENCES jadwal_dosen(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE progres_skripsi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mahasiswa_id INTEGER NOT NULL,
        dosen_id INTEGER NOT NULL,
        judul_skripsi TEXT NOT NULL,
        tahap TEXT NOT NULL,
        status TEXT DEFAULT 'belum',
        catatan TEXT,
        catatan_mahasiswa TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (mahasiswa_id) REFERENCES users(id),
        FOREIGN KEY (dosen_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE validasi_kehadiran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        booking_id INTEGER NOT NULL,
        dosen_id INTEGER NOT NULL,
        mahasiswa_id INTEGER NOT NULL,
        status_hadir TEXT DEFAULT 'belum_divalidasi',
        catatan TEXT,
        validated_at TEXT,
        FOREIGN KEY (booking_id) REFERENCES booking(id),
        FOREIGN KEY (dosen_id) REFERENCES users(id),
        FOREIGN KEY (mahasiswa_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE target_bimbingan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mahasiswa_id INTEGER NOT NULL UNIQUE,
        target_selesai TEXT NOT NULL,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (mahasiswa_id) REFERENCES users(id),
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Users
    await db.insert('users', {
      'nama': 'Adrian Pratama',
      'nim_nip': '60200121001',
      'email': 'adrian@mhs.edu',
      'password': 'mahasiswa123',
      'role': 'mahasiswa',
      'jurusan': 'Teknik Informatika'
    });
    await db.insert('users', {
      'nama': 'Lia Amalia',
      'nim_nip': '60200121002',
      'email': 'lia@mhs.edu',
      'password': 'mahasiswa123',
      'role': 'mahasiswa',
      'jurusan': 'Teknik Informatika'
    });
    await db.insert('users', {
      'nama': 'Budi Santoso',
      'nim_nip': '60200121003',
      'email': 'budi@mhs.edu',
      'password': 'mahasiswa123',
      'role': 'mahasiswa',
      'jurusan': 'Sistem Informasi'
    });

    await db.insert('users', {
      'nama': 'Dr. Heru Wijaya',
      'nim_nip': '198001012005011001',
      'email': 'heru@dsn.edu',
      'password': 'dosen123',
      'role': 'dosen',
      'jurusan': 'Teknik Informatika'
    });
    await db.insert('users', {
      'nama': 'Prof. Dr. Sarah Wijaya',
      'nim_nip': '197505152003122001',
      'email': 'sarah@dsn.edu',
      'password': 'dosen123',
      'role': 'dosen',
      'jurusan': 'Sistem Informasi'
    });

    await db.insert('users', {
      'nama': 'Dr. Aris Setiawan',
      'nim_nip': 'staf001',
      'email': 'aris@staf.edu',
      'password': 'staf123',
      'role': 'staf',
      'jurusan': 'Fakultas Teknik'
    });

    // Jadwal Dosen
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String tomorrow =
        DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));

    await db.insert('jadwal_dosen', {
      'dosen_id': 4,
      'hari': 'Senin',
      'tanggal': today,
      'jam_mulai': '09:00',
      'jam_selesai': '11:00',
      'status': 'tersedia',
      'lokasi': 'Ruang Dosen 1',
      'keterangan': 'Bimbingan Skripsi'
    });
    await db.insert('jadwal_dosen', {
      'dosen_id': 4,
      'hari': 'Senin',
      'tanggal': today,
      'jam_mulai': '13:00',
      'jam_selesai': '15:00',
      'status': 'penuh',
      'lokasi': 'Ruang Dosen 1',
      'keterangan': 'Bimbingan Skripsi'
    });
    await db.insert('jadwal_dosen', {
      'dosen_id': 5,
      'hari': 'Selasa',
      'tanggal': tomorrow,
      'jam_mulai': '10:00',
      'jam_selesai': '12:00',
      'status': 'tersedia',
      'lokasi': 'Ruang Dosen 2',
      'keterangan': 'Bimbingan Skripsi'
    });

    // Booking
    await db.insert('booking', {
      'mahasiswa_id': 1,
      'dosen_id': 4,
      'jadwal_id': 2,
      'keperluan': 'Konsultasi Bab 1',
      'status': 'approved',
      'catatan_staf': 'Silakan datang tepat waktu',
      'created_at': DateTime.now().toIso8601String()
    });
    await db.insert('booking', {
      'mahasiswa_id': 2,
      'dosen_id': 4,
      'jadwal_id': 1,
      'keperluan': 'Revisi Bab 3',
      'status': 'pending',
      'catatan_staf': null,
      'created_at': DateTime.now().toIso8601String()
    });

    // Progres Skripsi - semua tahapan untuk mahasiswa 1
    final tahapan = ['bab1', 'bab2', 'bab3', 'seminar_proposal', 'bab4_5', 'sidang', 'selesai'];
    final statusTahap = ['revisi', 'belum', 'belum', 'belum', 'belum', 'belum', 'belum'];
    final catatanTahap = [
      'Perbaiki latar belakang dan rumusan masalah.',
      null, null, null, null, null, null
    ];

    for (int i = 0; i < tahapan.length; i++) {
      await db.insert('progres_skripsi', {
        'mahasiswa_id': 1,
        'dosen_id': 4,
        'judul_skripsi': 'Sistem Prediksi Cuaca Berbasis AI',
        'tahap': tahapan[i],
        'status': statusTahap[i],
        'catatan': catatanTahap[i],
        'catatan_mahasiswa': null,
        'updated_at': DateTime.now().toIso8601String()
      });
    }

    // Progres Skripsi - semua tahapan untuk mahasiswa 2
    final statusTahap2 = ['acc', 'acc', 'acc', 'belum', 'belum', 'belum', 'belum'];
    final catatanTahap2 = [
      'Pendahuluan bagus.', 'Tinjauan pustaka lengkap.', 'Metodologi sudah sesuai.',
      null, null, null, null
    ];

    for (int i = 0; i < tahapan.length; i++) {
      await db.insert('progres_skripsi', {
        'mahasiswa_id': 2,
        'dosen_id': 4,
        'judul_skripsi': 'Aplikasi Booking Antrean Berbasis Mobile',
        'tahap': tahapan[i],
        'status': statusTahap2[i],
        'catatan': catatanTahap2[i],
        'catatan_mahasiswa': null,
        'updated_at': DateTime.now().toIso8601String()
      });
    }

    // Validasi Kehadiran
    await db.insert('validasi_kehadiran', {
      'booking_id': 1,
      'dosen_id': 4,
      'mahasiswa_id': 1,
      'status_hadir': 'belum_divalidasi',
      'catatan': null,
      'validated_at': null
    });

    // Target Bimbingan
    await _seedTargetBimbingan(db);
  }

  Future<void> _seedTargetBimbingan(Database db) async {
    final targetAdr =
        DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 45)));
    final targetLia =
        DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 120)));
    final targetBudi =
        DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 8)));

    try {
      await db.insert('target_bimbingan', {
        'mahasiswa_id': 1,
        'target_selesai': targetAdr,
        'created_by': 6,
        'created_at': DateTime.now().toIso8601String()
      });
    } catch (_) {}
    try {
      await db.insert('target_bimbingan', {
        'mahasiswa_id': 2,
        'target_selesai': targetLia,
        'created_by': 6,
        'created_at': DateTime.now().toIso8601String()
      });
    } catch (_) {}
    try {
      await db.insert('target_bimbingan', {
        'mahasiswa_id': 3,
        'target_selesai': targetBudi,
        'created_by': 6,
        'created_at': DateTime.now().toIso8601String()
      });
    } catch (_) {}
  }

  // === USERS ===
  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return UserModel.fromMap(maps.first);
    return null;
  }

  Future<UserModel?> login(String nimNip, String password) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'nim_nip = ? AND password = ?',
        whereArgs: [nimNip, password],
      );
      if (maps.isNotEmpty) return UserModel.fromMap(maps.first);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<UserModel>> getAllDosen() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('users', where: 'role = ?', whereArgs: ['dosen']);
    return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
  }

  Future<List<UserModel>> getAllMahasiswa() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('users', where: 'role = ?', whereArgs: ['mahasiswa']);
    return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db
        .update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // === JADWAL DOSEN ===
  Future<int> insertJadwal(JadwalModel jadwal) async {
    final db = await database;
    return await db.insert('jadwal_dosen', jadwal.toMap());
  }

  Future<List<JadwalModel>> getJadwalByDosen(int dosenId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        .query('jadwal_dosen', where: 'dosen_id = ?', whereArgs: [dosenId]);
    return List.generate(maps.length, (i) => JadwalModel.fromMap(maps[i]));
  }

  Future<List<JadwalModel>> getJadwalTersedia(int dosenId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'jadwal_dosen',
      where: 'dosen_id = ? AND status = ?',
      whereArgs: [dosenId, 'tersedia'],
    );
    return List.generate(maps.length, (i) => JadwalModel.fromMap(maps[i]));
  }

  Future<List<JadwalModel>> getJadwalByTanggal(
      int dosenId, String tanggal) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'jadwal_dosen',
      where: 'dosen_id = ? AND tanggal = ?',
      whereArgs: [dosenId, tanggal],
    );
    return List.generate(maps.length, (i) => JadwalModel.fromMap(maps[i]));
  }

  Future<int> updateStatusJadwal(int id, String status) async {
    final db = await database;
    return await db.update('jadwal_dosen', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateJadwal(JadwalModel jadwal) async {
    final db = await database;
    return await db.update('jadwal_dosen', jadwal.toMap(),
        where: 'id = ?', whereArgs: [jadwal.id]);
  }

  Future<int> deleteJadwal(int id) async {
    final db = await database;
    return await db.delete('jadwal_dosen', where: 'id = ?', whereArgs: [id]);
  }

  // === BOOKING ===
  Future<int> insertBooking(BookingModel booking) async {
    final db = await database;
    return await db.insert('booking', booking.toMap());
  }

  Future<List<BookingModel>> getBookingByMahasiswa(int mahasiswaId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT b.*, 
             u1.nama as nama_mahasiswa, u1.nim_nip as nim,
             u2.nama as nama_dosen,
             j.tanggal, j.jam_mulai as jam
      FROM booking b
      JOIN users u1 ON b.mahasiswa_id = u1.id
      JOIN users u2 ON b.dosen_id = u2.id
      JOIN jadwal_dosen j ON b.jadwal_id = j.id
      WHERE b.mahasiswa_id = ?
    ''', [mahasiswaId]);
    return List.generate(maps.length, (i) => BookingModel.fromMap(maps[i]));
  }

  Future<List<BookingModel>> getBookingByDosen(int dosenId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT b.*, 
             u1.nama as nama_mahasiswa, u1.nim_nip as nim,
             u2.nama as nama_dosen,
             j.tanggal, j.jam_mulai as jam
      FROM booking b
      JOIN users u1 ON b.mahasiswa_id = u1.id
      JOIN users u2 ON b.dosen_id = u2.id
      JOIN jadwal_dosen j ON b.jadwal_id = j.id
      WHERE b.dosen_id = ?
    ''', [dosenId]);
    return List.generate(maps.length, (i) => BookingModel.fromMap(maps[i]));
  }

  Future<List<BookingModel>> getAllBooking() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT b.*, 
             u1.nama as nama_mahasiswa, u1.nim_nip as nim,
             u2.nama as nama_dosen,
             j.tanggal, j.jam_mulai as jam
      FROM booking b
      JOIN users u1 ON b.mahasiswa_id = u1.id
      JOIN users u2 ON b.dosen_id = u2.id
      JOIN jadwal_dosen j ON b.jadwal_id = j.id
    ''');
    return List.generate(maps.length, (i) => BookingModel.fromMap(maps[i]));
  }

  Future<List<BookingModel>> getBookingByStatus(String status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT b.*, 
             u1.nama as nama_mahasiswa, u1.nim_nip as nim,
             u2.nama as nama_dosen,
             j.tanggal, j.jam_mulai as jam
      FROM booking b
      JOIN users u1 ON b.mahasiswa_id = u1.id
      JOIN users u2 ON b.dosen_id = u2.id
      JOIN jadwal_dosen j ON b.jadwal_id = j.id
      WHERE b.status = ?
    ''', [status]);
    return List.generate(maps.length, (i) => BookingModel.fromMap(maps[i]));
  }

  Future<int> updateStatusBooking(
      int id, String status, String? catatanStaf) async {
    final db = await database;
    return await db.update(
        'booking', {'status': status, 'catatan_staf': catatanStaf},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<BookingModel?> getBookingById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT b.*, 
             u1.nama as nama_mahasiswa, u1.nim_nip as nim,
             u2.nama as nama_dosen,
             j.tanggal, j.jam_mulai as jam
      FROM booking b
      JOIN users u1 ON b.mahasiswa_id = u1.id
      JOIN users u2 ON b.dosen_id = u2.id
      JOIN jadwal_dosen j ON b.jadwal_id = j.id
      WHERE b.id = ?
    ''', [id]);
    if (maps.isNotEmpty) return BookingModel.fromMap(maps.first);
    return null;
  }

  Future<int> deleteBooking(int id) async {
    final db = await database;
    return await db.delete('booking', where: 'id = ?', whereArgs: [id]);
  }

  // === PROGRES SKRIPSI ===
  Future<int> insertProgres(ProgresModel progres) async {
    final db = await database;
    return await db.insert('progres_skripsi', progres.toMap());
  }

  Future<ProgresModel?> getPregresByMahasiswa(int mahasiswaId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
        'progres_skripsi',
        where: 'mahasiswa_id = ?',
        whereArgs: [mahasiswaId]);
    if (maps.isNotEmpty) return ProgresModel.fromMap(maps.first);
    return null;
  }

  /// Ambil semua tahap progres untuk satu mahasiswa
  Future<List<ProgresModel>> getAllTahapByMahasiswa(int mahasiswaId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'progres_skripsi',
        where: 'mahasiswa_id = ?',
        whereArgs: [mahasiswaId],
        orderBy: 'id ASC',
      );
      return List.generate(maps.length, (i) => ProgresModel.fromMap(maps[i]));
    } catch (e) {
      return [];
    }
  }

  Future<List<ProgresModel>> getAllProgresByDosen(int dosenId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, u.nama as nama_mahasiswa
      FROM progres_skripsi p
      JOIN users u ON p.mahasiswa_id = u.id
      WHERE p.dosen_id = ?
    ''', [dosenId]);
    return List.generate(maps.length, (i) => ProgresModel.fromMap(maps[i]));
  }

  /// Ambil semua tahap per mahasiswa untuk dosen (digroup per mahasiswa)
  Future<Map<int, List<ProgresModel>>> getAllTahapGroupedByMahasiswaForDosen(
      int dosenId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT p.*, u.nama as nama_mahasiswa
        FROM progres_skripsi p
        JOIN users u ON p.mahasiswa_id = u.id
        WHERE p.dosen_id = ?
        ORDER BY p.mahasiswa_id ASC, p.id ASC
      ''', [dosenId]);

      final Map<int, List<ProgresModel>> grouped = {};
      for (final map in maps) {
        final progres = ProgresModel.fromMap(map);
        grouped.putIfAbsent(progres.mahasiswaId, () => []);
        grouped[progres.mahasiswaId]!.add(progres);
      }
      return grouped;
    } catch (e) {
      return {};
    }
  }

  /// Count tahap yang menunggu konfirmasi untuk dosen
  Future<int> countMenungguKonfirmasiByDosen(int dosenId) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count FROM progres_skripsi
        WHERE dosen_id = ? AND status = 'menunggu_konfirmasi'
      ''', [dosenId]);
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> updateProgres(ProgresModel progres) async {
    final db = await database;
    return await db.update('progres_skripsi', progres.toMap(),
        where: 'id = ?', whereArgs: [progres.id]);
  }

  Future<int> updateTahapProgres(
      int id, String tahap, String status, String? catatan) async {
    final db = await database;
    return await db.update(
      'progres_skripsi',
      {
        'tahap': tahap,
        'status': status,
        'catatan': catatan,
        'updated_at': DateTime.now().toIso8601String()
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update status dan catatan dosen pada satu tahap progres
  Future<int> updateStatusProgresById(
      int id, String status, String? catatan) async {
    try {
      final db = await database;
      return await db.update(
        'progres_skripsi',
        {
          'status': status,
          'catatan': catatan,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      return 0;
    }
  }

  /// Mahasiswa ajukan ke dosen (ubah status jadi 'menunggu_konfirmasi')
  Future<int> ajukanKeDosen(int id, String catatanMahasiswa) async {
    try {
      final db = await database;
      return await db.update(
        'progres_skripsi',
        {
          'status': 'menunggu_konfirmasi',
          'catatan_mahasiswa': catatanMahasiswa,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      return 0;
    }
  }

  // === VALIDASI KEHADIRAN ===
  Future<int> insertValidasi(ValidasiModel validasi) async {
    final db = await database;
    return await db.insert('validasi_kehadiran', validasi.toMap());
  }

  Future<ValidasiModel?> getValidasiByBooking(int bookingId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        .query('validasi_kehadiran', where: 'booking_id = ?', whereArgs: [bookingId]);
    if (maps.isNotEmpty) return ValidasiModel.fromMap(maps.first);
    return null;
  }

  Future<List<ValidasiModel>> getValidasiByDosen(int dosenId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        .query('validasi_kehadiran', where: 'dosen_id = ?', whereArgs: [dosenId]);
    return List.generate(maps.length, (i) => ValidasiModel.fromMap(maps[i]));
  }

  Future<int> updateValidasi(
      int id, String statusHadir, String? catatan) async {
    final db = await database;
    return await db.update(
      'validasi_kehadiran',
      {
        'status_hadir': statusHadir,
        'catatan': catatan,
        'validated_at': DateTime.now().toIso8601String()
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === TARGET BIMBINGAN ===
  Future<Map<String, dynamic>?> getTargetByMahasiswa(int mahasiswaId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'target_bimbingan',
        where: 'mahasiswa_id = ?',
        whereArgs: [mahasiswaId],
      );
      if (maps.isNotEmpty) return maps.first;
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllTargetByDosen(int dosenId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT t.*, u.nama as nama_mahasiswa, u.nim_nip
        FROM target_bimbingan t
        JOIN users u ON t.mahasiswa_id = u.id
        JOIN progres_skripsi p ON p.mahasiswa_id = t.mahasiswa_id
        WHERE p.dosen_id = ?
        GROUP BY t.mahasiswa_id
      ''', [dosenId]);
      return maps;
    } catch (e) {
      return [];
    }
  }

  Future<int> upsertTarget(
      int mahasiswaId, String targetSelesai, int createdBy) async {
    try {
      final db = await database;
      final existing = await getTargetByMahasiswa(mahasiswaId);
      if (existing != null) {
        return await db.update(
          'target_bimbingan',
          {
            'target_selesai': targetSelesai,
            'created_by': createdBy,
            'created_at': DateTime.now().toIso8601String(),
          },
          where: 'mahasiswa_id = ?',
          whereArgs: [mahasiswaId],
        );
      } else {
        return await db.insert('target_bimbingan', {
          'mahasiswa_id': mahasiswaId,
          'target_selesai': targetSelesai,
          'created_by': createdBy,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      return 0;
    }
  }
}
