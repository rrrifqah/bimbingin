// Model untuk data pengguna (mahasiswa, dosen, staf)
class UserModel {
  final int? id;
  final String nama;
  final String nimNip;
  final String email;
  final String password;
  final String role; // 'mahasiswa', 'dosen', 'staf'
  final String jurusan;
  final String? foto;

  // Field tambahan khusus dosen
  final String? nidn; // Nomor Induk Dosen Nasional
  final String? prodi; // Program Studi
  final String? bidangKeahlian; // Bidang Keahlian dosen
  final String? phone; // Nomor HP

  UserModel({
    this.id,
    required this.nama,
    required this.nimNip,
    required this.email,
    required this.password,
    required this.role,
    required this.jurusan,
    this.foto,
    this.nidn,
    this.prodi,
    this.bidangKeahlian,
    this.phone,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      nama: map['nama'] ?? '',
      nimNip: map['nim_nip'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? 'mahasiswa',
      jurusan: map['jurusan'] ?? '',
      foto: map['foto'],
      nidn: map['nidn'],
      prodi: map['prodi'],
      bidangKeahlian: map['bidang_keahlian'],
      phone: map['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'nim_nip': nimNip,
      'email': email,
      'password': password,
      'role': role,
      'jurusan': jurusan,
      'foto': foto,
      'nidn': nidn,
      'prodi': prodi,
      'bidang_keahlian': bidangKeahlian,
      'phone': phone,
    };
  }

  UserModel copyWith({
    int? id,
    String? nama,
    String? nimNip,
    String? email,
    String? password,
    String? role,
    String? jurusan,
    String? foto,
    String? nidn,
    String? prodi,
    String? bidangKeahlian,
    String? phone,
  }) {
    return UserModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      nimNip: nimNip ?? this.nimNip,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      jurusan: jurusan ?? this.jurusan,
      foto: foto ?? this.foto,
      nidn: nidn ?? this.nidn,
      prodi: prodi ?? this.prodi,
      bidangKeahlian: bidangKeahlian ?? this.bidangKeahlian,
      phone: phone ?? this.phone,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nama: $nama, nimNip: $nimNip, role: $role)';
  }
}
