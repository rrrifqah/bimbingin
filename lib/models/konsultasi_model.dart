class KonsultasiModel {
  final int? id;
  final int mahasiswaId;
  final int? dosenId;
  final String tanggal;
  final String isiKonsultasi;
  final String status; // 'acc' atau 'revisi'
  final String createdAt;

  KonsultasiModel({
    this.id,
    required this.mahasiswaId,
    this.dosenId,
    required this.tanggal,
    required this.isiKonsultasi,
    required this.status,
    required this.createdAt,
  });

  factory KonsultasiModel.fromMap(Map<String, dynamic> map) {
    return KonsultasiModel(
      id: map['id'],
      mahasiswaId: map['mahasiswa_id'],
      dosenId: map['dosen_id'],
      tanggal: map['tanggal'],
      isiKonsultasi: map['isi_konsultasi'],
      status: map['status'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mahasiswa_id': mahasiswaId,
      'dosen_id': dosenId,
      'tanggal': tanggal,
      'isi_konsultasi': isiKonsultasi,
      'status': status,
      'created_at': createdAt,
    };
  }

  KonsultasiModel copyWith({
    int? id,
    int? mahasiswaId,
    int? dosenId,
    String? tanggal,
    String? isiKonsultasi,
    String? status,
    String? createdAt,
  }) {
    return KonsultasiModel(
      id: id ?? this.id,
      mahasiswaId: mahasiswaId ?? this.mahasiswaId,
      dosenId: dosenId ?? this.dosenId,
      tanggal: tanggal ?? this.tanggal,
      isiKonsultasi: isiKonsultasi ?? this.isiKonsultasi,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'KonsultasiModel(id: $id, mahasiswaId: $mahasiswaId, dosenId: $dosenId, tanggal: $tanggal, status: $status)';
  }
}
