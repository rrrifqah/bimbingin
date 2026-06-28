class JadwalModel {
  final int? id;
  final int dosenId;
  final String? namaDosen;
  final String hari;
  final String tanggal;
  final String jamMulai;
  final String jamSelesai;
  final String status; // 'tersedia', 'penuh'
  final String lokasi;
  final String? keterangan;

  JadwalModel({
    this.id,
    required this.dosenId,
    this.namaDosen,
    required this.hari,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.status,
    required this.lokasi,
    this.keterangan,
  });

  factory JadwalModel.fromMap(Map<String, dynamic> map) {
    return JadwalModel(
      id: map['id'],
      dosenId: map['dosen_id'],
      namaDosen: map['nama_dosen'],
      hari: map['hari'],
      tanggal: map['tanggal'],
      jamMulai: map['jam_mulai'],
      jamSelesai: map['jam_selesai'],
      status: map['status'] ?? 'tersedia',
      lokasi: map['lokasi'],
      keterangan: map['keterangan'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dosen_id': dosenId,
      'hari': hari,
      'tanggal': tanggal,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'status': status,
      'lokasi': lokasi,
      'keterangan': keterangan,
    };
  }

  JadwalModel copyWith({
    int? id,
    int? dosenId,
    String? namaDosen,
    String? hari,
    String? tanggal,
    String? jamMulai,
    String? jamSelesai,
    String? status,
    String? lokasi,
    String? keterangan,
  }) {
    return JadwalModel(
      id: id ?? this.id,
      dosenId: dosenId ?? this.dosenId,
      namaDosen: namaDosen ?? this.namaDosen,
      hari: hari ?? this.hari,
      tanggal: tanggal ?? this.tanggal,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      status: status ?? this.status,
      lokasi: lokasi ?? this.lokasi,
      keterangan: keterangan ?? this.keterangan,
    );
  }

  @override
  String toString() {
    return 'JadwalModel(id: $id, dosenId: $dosenId, hari: $hari, status: $status)';
  }
}
