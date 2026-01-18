
class UserModel {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String cedula;
  final String? telefono;
  final String? genero;
  final String role;
  final bool emailVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.cedula,
    this.telefono,
    this.genero,
    required this.role,
    required this.emailVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convertir JSON a UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      email: json['email'] as String? ?? '',
      cedula: json['cedula'] as String? ?? '',
      telefono: json['telefono'] as String?,
      genero: json['genero'] as String?,
      role: json['role'] as String? ?? 'client',
      emailVerified: json['emailVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convertir UserModel a JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'cedula': cedula,
      'telefono': telefono,
      'genero': genero,
      'role': role,
      'emailVerified': emailVerified,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// CopyWith para actualizar campos
  UserModel copyWith({
    String? id,
    String? nombre,
    String? apellido,
    String? email,
    String? cedula,
    String? telefono,
    String? genero,
    String? role,
    bool? emailVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      email: email ?? this.email,
      cedula: cedula ?? this.cedula,
      telefono: telefono ?? this.telefono,
      genero: genero ?? this.genero,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nombre: $nombre, apellido: $apellido, email: $email)';
  }
}
