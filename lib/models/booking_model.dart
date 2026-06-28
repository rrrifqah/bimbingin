class BookingModel {
  final int? id;
  final int mahasiswaId;
  final String? namaMahasiswa;
  final String? nim;
  final int dosenId;
  final String? namaDosen;
  final int jadwalId;
  final String? tanggal;
  final String? jam;
  final String keperluan;
  final String status; // 'pending', 'approved', 'rejected'
  final String? catatanStaf;
  final String createdAt;

  BookingModel({
    this.id,
    required this.mahasiswaId,
    this.namaMahasiswa,
    this.nim,
    required this.dosenId,
    this.namaDosen,
    required this.jadwalId,
    this.tanggal,
    this.jam,
    required this.keperluan,
    required this.status,
    this.catatanStaf,
    required this.createdAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'],
      mahasiswaId: map['mahasiswa_id'],
      namaMahasiswa: map['nama_mahasiswa'],
      nim: map['nim'],
      dosenId: map['dosen_id'],
      namaDosen: map['nama_dosen'],
      jadwalId: map['jadwal_id'],
      tanggal: map['tanggal'],
      jam: map['jam'],
      keperluan: map['keperluan'],
      status: map['status'] ?? 'pending',
      catatanStaf: map['catatan_staf'],
      createdAt: map['created_at'],
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
    int? jadwalId,
    String? tanggal,
    String? jam,
    String? keperluan,
    String? status,
    String? catatanStaf,
    String? createdAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      mahasiswaId: mahasiswaId ?? this.mahasiswaId,
      namaMahasiswa: namaMahasiswa ?? this.namaMahasiswa,
      nim: nim ?? this.nim,
      dosenId: dosenId ?? this.dosenId,
      namaDosen: namaDosen ?? this.namaDosen,
      jadwalId: jadwalId ?? this.jadwalId,
      tanggal: tanggal ?? this.tanggal,
      jam: jam ?? this.jam,
      keperluan: keperluan ?? this.keperluan,
      status: status ?? this.status,
      catatanStaf: catatanStaf ?? this.catatanStaf,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'BookingModel(id: $id, mahasiswaId: $mahasiswaId, jadwalId: $jadwalId, status: $status)';
  }
}
