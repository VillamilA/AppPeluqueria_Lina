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
  // Email con estructura clara (ejemplo@dominio.com)
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    return emailRegex.hasMatch(email);
  }

  static String? validateEmailMessage(String email) {
    if (email.isEmpty) return 'El correo es requerido';
    if (!isValidEmail(email)) {
      return 'Formato inválido (ej: usuario@ejemplo.com)';
    }
    return null;
  }

  static bool isValidPassword(String password) {
    // Mínimo 8 caracteres, mayúscula, minúscula, número, carácter especial (cualquiera)
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\w\s])[^\s]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  static String? validatePasswordMessage(String password) {
    if (password.isEmpty) return 'La contraseña es requerida';
    if (password.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Se requiere una MAYÚSCULA';
    if (!RegExp(r'[a-z]').hasMatch(password)) return 'Se requiere una minúscula';
    if (!RegExp(r'\d').hasMatch(password)) return 'Se requiere un número';
    if (!RegExp(r'[^\w\s]').hasMatch(password)) return 'Se requiere un carácter especial (.#\$%! etc)';
    return null;
  }

  // Verificar requisitos individuales de contraseña
  static Map<String, bool> getPasswordRequirements(String password) {
    return {
      '8 caracteres mínimo': password.length >= 8,
      'Una MAYÚSCULA': RegExp(r'[A-Z]').hasMatch(password),
      'Una minúscula': RegExp(r'[a-z]').hasMatch(password),
      'Un número (0-9)': RegExp(r'\d').hasMatch(password),
      'Carácter especial (.#\$%! etc)': RegExp(r'[^\w\s]').hasMatch(password),
    };
  }

  // Cédula: solo números, máximo 10 dígitos
  static bool isValidCedula(String cedula) {
    if (cedula.isEmpty) return false;
    final cedulaRegex = RegExp(r'^\d{1,10}$');
    return cedulaRegex.hasMatch(cedula) && cedula.length <= 10;
  }

  static String? validateCedulaMessage(String cedula) {
    if (cedula.isEmpty) return 'La cédula es requerida';
    if (!RegExp(r'^\d+$').hasMatch(cedula)) {
      return 'Solo se permiten números';
    }
    if (cedula.length > 10) {
      return 'Máximo 10 dígitos';
    }
    return null;
  }

  // Teléfono: debe comenzar con 09, máximo 10 dígitos
  static bool isValidPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final phoneRegex = RegExp(r'^09\d{8}$');
    return phoneRegex.hasMatch(cleanPhone) && cleanPhone.length == 10;
  }

  static String? validatePhoneMessage(String phone) {
    if (phone.isEmpty) return 'El teléfono es requerido';
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d+$').hasMatch(cleanPhone)) {
      return 'Solo se permiten números';
    }
    if (!cleanPhone.startsWith('09')) {
      return 'Debe comenzar con 09';
    }
    if (cleanPhone.length != 10) {
      return 'Debe tener 10 dígitos';
    }
    return null;
  }

  // Nombre/Apellido: mínimo 3 caracteres, solo letras
  static bool isValidName(String name) {
    if (name.isEmpty || name.length < 3) return false;
    final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]{3,}$');
    return nameRegex.hasMatch(name);
  }

  static String? validateNameMessage(String name) {
    if (name.isEmpty) return 'Este campo es requerido';
    if (name.length < 3) {
      return 'Mínimo 3 caracteres';
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(name)) {
      return 'Solo se permiten letras y espacios';
    }
    return null;
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
