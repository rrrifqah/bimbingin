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
      version: 1,
      onCreate: _onCreate,
    );
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
    String tomorrow = DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: 1)));
    
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

    // Progres Skripsi
    await db.insert('progres_skripsi', {
      'mahasiswa_id': 1,
      'dosen_id': 4,
      'judul_skripsi': 'Sistem Prediksi Cuaca Berbasis AI',
      'tahap': 'bab1',
      'status': 'revisi',
      'catatan': 'Perbaiki latar belakang',
      'updated_at': DateTime.now().toIso8601String()
    });
    await db.insert('progres_skripsi', {
      'mahasiswa_id': 2,
      'dosen_id': 4,
      'judul_skripsi': 'Aplikasi Booking Antrean Berbasis Mobile',
      'tahap': 'bab3',
      'status': 'acc',
      'catatan': 'Lanjut ke bab 4',
      'updated_at': DateTime.now().toIso8601String()
    });

    // Validasi Kehadiran
    await db.insert('validasi_kehadiran', {
      'booking_id': 1,
      'dosen_id': 4,
      'mahasiswa_id': 1,
      'status_hadir': 'belum_divalidasi',
      'catatan': null,
      'validated_at': null
    });
  }

  // === USERS ===
  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return UserModel.fromMap(maps.first);
    return null;
  }

  Future<UserModel?> login(String nimNip, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'nim_nip = ? AND password = ?',
      whereArgs: [nimNip, password],
    );
    if (maps.isNotEmpty) return UserModel.fromMap(maps.first);
    return null;
  }

  Future<List<UserModel>> getAllDosen() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', where: 'role = ?', whereArgs: ['dosen']);
    return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
  }

  Future<List<UserModel>> getAllMahasiswa() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', where: 'role = ?', whereArgs: ['mahasiswa']);
    return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
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
    final List<Map<String, dynamic>> maps = await db.query('jadwal_dosen', where: 'dosen_id = ?', whereArgs: [dosenId]);
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

  Future<List<JadwalModel>> getJadwalByTanggal(int dosenId, String tanggal) async {
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
    return await db.update('jadwal_dosen', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateJadwal(JadwalModel jadwal) async {
    final db = await database;
    return await db.update('jadwal_dosen', jadwal.toMap(), where: 'id = ?', whereArgs: [jadwal.id]);
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

  Future<int> updateStatusBooking(int id, String status, String? catatanStaf) async {
    final db = await database;
    return await db.update(
      'booking', 
      {'status': status, 'catatan_staf': catatanStaf}, 
      where: 'id = ?', 
      whereArgs: [id]
    );
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
    final List<Map<String, dynamic>> maps = await db.query('progres_skripsi', where: 'mahasiswa_id = ?', whereArgs: [mahasiswaId]);
    if (maps.isNotEmpty) return ProgresModel.fromMap(maps.first);
    return null;
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

  Future<int> updateProgres(ProgresModel progres) async {
    final db = await database;
    return await db.update('progres_skripsi', progres.toMap(), where: 'id = ?', whereArgs: [progres.id]);
  }

  Future<int> updateTahapProgres(int id, String tahap, String status, String? catatan) async {
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
      whereArgs: [id]
    );
  }

  // === VALIDASI KEHADIRAN ===
  Future<int> insertValidasi(ValidasiModel validasi) async {
    final db = await database;
    return await db.insert('validasi_kehadiran', validasi.toMap());
  }

  Future<ValidasiModel?> getValidasiByBooking(int bookingId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('validasi_kehadiran', where: 'booking_id = ?', whereArgs: [bookingId]);
    if (maps.isNotEmpty) return ValidasiModel.fromMap(maps.first);
    return null;
  }

  Future<List<ValidasiModel>> getValidasiByDosen(int dosenId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('validasi_kehadiran', where: 'dosen_id = ?', whereArgs: [dosenId]);
    return List.generate(maps.length, (i) => ValidasiModel.fromMap(maps[i]));
  }

  Future<int> updateValidasi(int id, String statusHadir, String? catatan) async {
    final db = await database;
    return await db.update(
      'validasi_kehadiran', 
      {
        'status_hadir': statusHadir,
        'catatan': catatan,
        'validated_at': DateTime.now().toIso8601String()
      }, 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }
}
