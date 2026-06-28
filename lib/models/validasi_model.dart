class ValidasiModel {
  final int? id;
  final int bookingId;
  final int dosenId;
  final int mahasiswaId;
  final String statusHadir; // 'hadir', 'tidak_hadir', 'belum_divalidasi'
  final String? catatan;
  final String? validatedAt;

  ValidasiModel({
    this.id,
    required this.bookingId,
    required this.dosenId,
    required this.mahasiswaId,
    required this.statusHadir,
    this.catatan,
    this.validatedAt,
  });

  factory ValidasiModel.fromMap(Map<String, dynamic> map) {
    return ValidasiModel(
      id: map['id'],
      bookingId: map['booking_id'],
      dosenId: map['dosen_id'],
      mahasiswaId: map['mahasiswa_id'],
      statusHadir: map['status_hadir'] ?? 'belum_divalidasi',
      catatan: map['catatan'],
      validatedAt: map['validated_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'dosen_id': dosenId,
      'mahasiswa_id': mahasiswaId,
      'status_hadir': statusHadir,
      'catatan': catatan,
      'validated_at': validatedAt,
    };
  }

  ValidasiModel copyWith({
    int? id,
    int? bookingId,
    int? dosenId,
    int? mahasiswaId,
    String? statusHadir,
    String? catatan,
    String? validatedAt,
  }) {
    return ValidasiModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      dosenId: dosenId ?? this.dosenId,
      mahasiswaId: mahasiswaId ?? this.mahasiswaId,
      statusHadir: statusHadir ?? this.statusHadir,
      catatan: catatan ?? this.catatan,
      validatedAt: validatedAt ?? this.validatedAt,
    );
  }

  @override
  String toString() {
    return 'ValidasiModel(id: $id, bookingId: $bookingId, statusHadir: $statusHadir)';
  }
}
