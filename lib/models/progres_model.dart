class ProgresModel {
  final int? id;
  final int mahasiswaId;
  final String? namaMahasiswa;
  final int dosenId;
  final String tahap;
  final String judulSkripsi;
  final String status; // 'belum', 'revisi', 'acc'
  final String? catatan;
  final String updatedAt;

  ProgresModel({
    this.id,
    required this.mahasiswaId,
    this.namaMahasiswa,
    required this.dosenId,
    required this.tahap,
    required this.judulSkripsi,
    required this.status,
    this.catatan,
    required this.updatedAt,
  });

  factory ProgresModel.fromMap(Map<String, dynamic> map) {
    return ProgresModel(
      id: map['id'],
      mahasiswaId: map['mahasiswa_id'],
      namaMahasiswa: map['nama_mahasiswa'],
      dosenId: map['dosen_id'],
      tahap: map['tahap'],
      judulSkripsi: map['judul_skripsi'],
      status: map['status'] ?? 'belum',
      catatan: map['catatan'],
      updatedAt: map['updated_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mahasiswa_id': mahasiswaId,
      'dosen_id': dosenId,
      'tahap': tahap,
      'judul_skripsi': judulSkripsi,
      'status': status,
      'catatan': catatan,
      'updated_at': updatedAt,
    };
  }

  ProgresModel copyWith({
    int? id,
    int? mahasiswaId,
    String? namaMahasiswa,
    int? dosenId,
    String? tahap,
    String? judulSkripsi,
    String? status,
    String? catatan,
    String? updatedAt,
  }) {
    return ProgresModel(
      id: id ?? this.id,
      mahasiswaId: mahasiswaId ?? this.mahasiswaId,
      namaMahasiswa: namaMahasiswa ?? this.namaMahasiswa,
      dosenId: dosenId ?? this.dosenId,
      tahap: tahap ?? this.tahap,
      judulSkripsi: judulSkripsi ?? this.judulSkripsi,
      status: status ?? this.status,
      catatan: catatan ?? this.catatan,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ProgresModel(id: $id, mahasiswaId: $mahasiswaId, tahap: $tahap, status: $status)';
  }
}
