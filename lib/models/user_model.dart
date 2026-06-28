class UserModel {
  final int? id;
  final String nama;
  final String nimNip;
  final String email;
  final String password;
  final String role; // 'mahasiswa', 'dosen', 'staf'
  final String jurusan;
  final String? foto;

  UserModel({
    this.id,
    required this.nama,
    required this.nimNip,
    required this.email,
    required this.password,
    required this.role,
    required this.jurusan,
    this.foto,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      nama: map['nama'],
      nimNip: map['nim_nip'],
      email: map['email'],
      password: map['password'],
      role: map['role'],
      jurusan: map['jurusan'],
      foto: map['foto'],
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
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nama: $nama, nimNip: $nimNip, role: $role)';
  }
}
