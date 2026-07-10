class BookingModel {
  final int? id;
  final int mahasiswaId;
  final String? namaMahasiswa;
  final String? nim;
  final int dosenId;
  final String? namaDosen;
  final String? fotoDosen;
  final int jadwalId;
  final String? tanggal;
  final String? jam;
  final String? jamMulai;
  final String? jamSelesai;
  final String keperluan;
  final String status; // 'pending', 'approved', 'rejected'
  final String? catatanStaf;
  final String createdAt;
  final int? nomorAntrian;
  final String? bookingTime;

  BookingModel({
    this.id,
    required this.mahasiswaId,
    this.namaMahasiswa,
    this.nim,
    required this.dosenId,
    this.namaDosen,
    this.fotoDosen,
    required this.jadwalId,
    this.tanggal,
    this.jam,
    this.jamMulai,
    this.jamSelesai,
    required this.keperluan,
    required this.status,
    this.catatanStaf,
    required this.createdAt,
    this.nomorAntrian,
    this.bookingTime,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    // Parsing nested user (mahasiswa) relation
    String? parsedNamaMhs = map['nama_mahasiswa'];
    String? parsedNim = map['nim'];
    if (map['users'] is Map) {
      parsedNamaMhs = map['users']['nama'];
      parsedNim = map['users']['nim_nip'];
    } else if (map['mahasiswa'] is Map) {
      parsedNamaMhs = map['mahasiswa']['nama'];
      parsedNim = map['mahasiswa']['nim_nip'];
    }

    // Parsing nested dosen relation
    String? parsedNamaDosen = map['nama_dosen'];
    String? parsedFotoDosen = map['foto_dosen'];
    if (map['dosen'] is Map) {
      parsedNamaDosen = map['dosen']['nama'];
      parsedFotoDosen = map['dosen']['foto'];
    }

    // Parsing nested jadwal_dosen relation
    String? parsedTanggal = map['tanggal'];
    String? parsedJam = map['jam'];
    String? parsedJamMulai = map['jam_mulai'];
    String? parsedJamSelesai = map['jam_selesai'];
    if (map['jadwal_dosen'] is Map) {
      parsedTanggal = map['jadwal_dosen']['tanggal'];
      parsedJamMulai = map['jadwal_dosen']['jam_mulai'];
      parsedJamSelesai = map['jadwal_dosen']['jam_selesai'];
      final mulai = parsedJamMulai ?? '';
      final selesai = parsedJamSelesai ?? '';
      parsedJam = (mulai.isNotEmpty && selesai.isNotEmpty)
          ? '$mulai - $selesai'
          : '$mulai$selesai';
    }

    return BookingModel(
      id: map['id'],
      mahasiswaId: map['mahasiswa_id'],
      namaMahasiswa: parsedNamaMhs,
      nim: parsedNim,
      dosenId: map['dosen_id'],
      namaDosen: parsedNamaDosen,
      fotoDosen: parsedFotoDosen,
      jadwalId: map['jadwal_id'],
      tanggal: parsedTanggal,
      jam: parsedJam,
      jamMulai: parsedJamMulai,
      jamSelesai: parsedJamSelesai,
      keperluan: map['keperluan'] ?? '',
      status: map['status'] ?? 'pending',
      catatanStaf: map['catatan_staf'],
      createdAt: map['created_at'] ?? '',
      nomorAntrian: map['nomor_antrian'],
      bookingTime: map['booking_time'] ?? map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mahasiswa_id': mahasiswaId,
      'dosen_id': dosenId,
      'jadwal_id': jadwalId,
      'keperluan': keperluan,
      'status': status,
      'catatan_staf': catatanStaf,
      'created_at': createdAt,
    };
  }

  BookingModel copyWith({
    int? id,
    int? mahasiswaId,
    String? namaMahasiswa,
    String? nim,
    int? dosenId,
    String? namaDosen,
    String? fotoDosen,
    int? jadwalId,
    String? tanggal,
    String? jam,
    String? jamMulai,
    String? jamSelesai,
    String? keperluan,
    String? status,
    String? catatanStaf,
    String? createdAt,
    int? nomorAntrian,
    String? bookingTime,
  }) {
    return BookingModel(
      id: id ?? this.id,
      mahasiswaId: mahasiswaId ?? this.mahasiswaId,
      namaMahasiswa: namaMahasiswa ?? this.namaMahasiswa,
      nim: nim ?? this.nim,
      dosenId: dosenId ?? this.dosenId,
      namaDosen: namaDosen ?? this.namaDosen,
      fotoDosen: fotoDosen ?? this.fotoDosen,
      jadwalId: jadwalId ?? this.jadwalId,
      tanggal: tanggal ?? this.tanggal,
      jam: jam ?? this.jam,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      keperluan: keperluan ?? this.keperluan,
      status: status ?? this.status,
      catatanStaf: catatanStaf ?? this.catatanStaf,
      createdAt: createdAt ?? this.createdAt,
      nomorAntrian: nomorAntrian ?? this.nomorAntrian,
      bookingTime: bookingTime ?? this.bookingTime,
    );
  }

  @override
  String toString() {
    return 'BookingModel(id: $id, mahasiswaId: $mahasiswaId, jadwalId: $jadwalId, status: $status, nomorAntrian: $nomorAntrian)';
  }
}
