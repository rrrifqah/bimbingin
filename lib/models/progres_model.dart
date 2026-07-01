class ProgresModel {
  final int? id;
  final int mahasiswaId;
  final String? namaMahasiswa;
  final int dosenId;
  final String tahap;
  final String judulSkripsi;
  // Status: 'belum' | 'revisi' | 'menunggu_konfirmasi' | 'acc'
  final String status;
  final String? catatan;
  final String? catatanMahasiswa;
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
    this.catatanMahasiswa,
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
      catatanMahasiswa: map['catatan_mahasiswa'],
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
      'catatan_mahasiswa': catatanMahasiswa,
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
    String? catatanMahasiswa,
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
      catatanMahasiswa: catatanMahasiswa ?? this.catatanMahasiswa,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Label nama tahap yang tampil di UI
  String get tahapLabel {
    switch (tahap) {
      case 'bab1':
        return 'Bab 1: Pendahuluan';
      case 'bab2':
        return 'Bab 2: Tinjauan Pustaka';
      case 'bab3':
        return 'Bab 3: Metodologi';
      case 'seminar_proposal':
        return 'Seminar Proposal';
      case 'bab4_5':
        return 'Bab 4 & 5: Implementasi';
      case 'sidang':
        return 'Sidang Skripsi';
      case 'selesai':
        return 'Selesai';
      default:
        return tahap;
    }
  }

  @override
  String toString() {
    return 'ProgresModel(id: $id, mahasiswaId: $mahasiswaId, tahap: $tahap, status: $status)';
  }
}
