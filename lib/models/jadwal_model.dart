class JadwalModel {
  final int? id;
  final int dosenId;
  final String? namaDosen;
  final String hari;
  final String? tanggal;
  final String jamMulai;
  final String jamSelesai;
  final String status; // 'tersedia', 'penuh'
  final String? lokasi;
  final String? keterangan;
  final int kuota;
  final int sisaSlot;

  JadwalModel({
    this.id,
    required this.dosenId,
    this.namaDosen,
    required this.hari,
    this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.status,
    this.lokasi,
    this.keterangan,
    required this.kuota,
    required this.sisaSlot,
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
      kuota: map['kuota'] ?? 1,
      sisaSlot: map['sisa_slot'] ?? 1,
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
      'kuota': kuota,
      'sisa_slot': sisaSlot,
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
    int? kuota,
    int? sisaSlot,
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
      kuota: kuota ?? this.kuota,
      sisaSlot: sisaSlot ?? this.sisaSlot,
    );
  }

  @override
  String toString() {
    return 'JadwalModel(id: $id, dosenId: $dosenId, hari: $hari, status: $status, kuota: $kuota, sisaSlot: $sisaSlot)';
  }
}
