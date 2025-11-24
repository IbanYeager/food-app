class User {
  final int id;
  final String nama;
  final String email;
  final String noHp;
  final String? foto; // Foto bisa jadi null

  User({
    required this.id,
    required this.nama,
    required this.email,
    required this.noHp,
    this.foto,
  });

  // Factory constructor untuk membuat User dari Map (data JSON)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nama: json['nama'] ?? 'Tanpa Nama',
      email: json['email'] ?? 'Tanpa Email',
      noHp: json['no_hp'] ?? 'Tanpa No. HP',
      foto: json['foto'],
    );
  }
}

