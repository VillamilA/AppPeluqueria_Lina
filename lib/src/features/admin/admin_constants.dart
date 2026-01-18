// Constantes y helpers para módulos CRUD del admin

class AdminConstants {
  // Roles
  static const String ROLE_GERENTE = 'GERENTE';
  static const String ROLE_CLIENTE = 'CLIENTE';
  static const String ROLE_ESTILISTA = 'ESTILISTA';

  // Catálogos disponibles (según tu backend)
  static const String DEFAULT_CATALOG_ID = '691b7cf3062a259aa1a17f2b';

  // Campos de formularios
  static const List<String> USER_FORM_FIELDS = [
    'nombre',
    'apellido',
    'cedula',
    'telefono',
    'genero',
    'email',
    'password',
  ];

  static const List<String> STYLIST_FORM_FIELDS = [
    'nombre',
    'apellido',
    'cedula',
    'telefono',
    'genero',
    'edad',
    'email',
    'password',
    'catalogs',
  ];
}

// Validaciones
class FormValidations {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    // Mínimo 8 caracteres, mayúscula, minúscula, número, carácter especial
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  static bool isValidCedula(String cedula) {
    return cedula.isNotEmpty && cedula.length >= 10;
  }

  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^(\+593|0)[0-9]{9,10}$');
    return phoneRegex.hasMatch(phone.replaceAll(' ', ''));
  }
}

// Helper para construir datos del formulario
class FormBuilder {
  static Map<String, dynamic> buildUserData({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required String genero,
    required String email,
    required String password,
    required String role,
  }) {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'cedula': cedula,
      'telefono': telefono,
      'genero': genero,
      'email': email,
      'password': password,
      'role': role,
    };
  }

  static Map<String, dynamic> buildStylistData({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required String genero,
    required int edad,
    required String email,
    required String password,
    List<String>? catalogs,
  }) {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'cedula': cedula,
      'telefono': telefono,
      'genero': genero,
      'edad': edad,
      'email': email,
      'password': password,
      'catalogs': catalogs ?? [AdminConstants.DEFAULT_CATALOG_ID],
    };
  }

  static Map<String, dynamic> buildClientData({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required String genero,
    required String email,
    required String password,
    bool isEdit = false,
  }) {
    final data = <String, dynamic>{
      'nombre': nombre,
      'apellido': apellido,
      'cedula': cedula,
      'telefono': telefono,
      'genero': genero,
    };

    if (password.isNotEmpty) {
      data['password'] = password;
    }

    // Email solo en creación (no permitido en edición)
    if (!isEdit) {
      data['email'] = email;
    }

    return data;
  }
}
