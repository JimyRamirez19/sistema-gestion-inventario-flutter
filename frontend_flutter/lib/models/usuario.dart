class Usuario {
  final int id;
  final String nombre;
  final String email;
  final bool isActive;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    this.isActive = true,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'is_active': isActive,
    };
  }

  @override
  String toString() => 'Usuario(id: $id, nombre: $nombre, email: $email, isActive: $isActive)';
}

