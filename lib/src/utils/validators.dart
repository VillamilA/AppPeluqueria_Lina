/// Validadores para formularios de la aplicación

/// Clase para validar requisitos de contraseña y obtener su estado
class PasswordStrengthChecker {
  static const minLength = 8;
  static const specialChars = '.#\$%&@!*-_=+';
  
  /// Verifica si tiene mínimo 8 caracteres
  static bool hasMinLength(String password) => password.length >= minLength;
  
  /// Verifica si tiene al menos una mayúscula
  static bool hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);
  
  /// Verifica si tiene al menos una minúscula
  static bool hasLowercase(String password) => RegExp(r'[a-z]').hasMatch(password);
  
  /// Verifica si tiene al menos un número
  static bool hasNumber(String password) => RegExp(r'[0-9]').hasMatch(password);
  
  /// Verifica si tiene al menos un carácter especial
  static bool hasSpecialChar(String password) => 
    RegExp(r'[.#$%&@!*\-_=+]').hasMatch(password);
  
  /// Obtiene todos los requisitos y su estado
  static Map<String, bool> getAllRequirements(String password) {
    return {
      '8 caracteres mínimo': hasMinLength(password),
      'Una MAYÚSCULA': hasUppercase(password),
      'Una minúscula': hasLowercase(password),
      'Un número (0-9)': hasNumber(password),
      'Carácter especial (.#\$%&@!*)': hasSpecialChar(password),
    };
  }
  
  /// Verifica si todos los requisitos se cumplen
  static bool isValid(String password) {
    final reqs = getAllRequirements(password);
    return reqs.values.every((element) => element);
  }
}

class FormValidators {
  /// Valida que un nombre sea válido (min 3 letras, solo letras y espacios)
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 3) {
      return '$fieldName debe tener mínimo 3 caracteres';
    }
    
    // Solo letras y espacios permitidos
    if (!RegExp(r'^[a-záéíóúñA-ZÁÉÍÓÚÑ\s]+$').hasMatch(trimmed)) {
      return '$fieldName solo puede contener letras y espacios';
    }
    
    return null;
  }

  /// Valida nombre de servicio (max 30 caracteres, solo letras y espacios)
  static String? validateServiceName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nombre del servicio es requerido';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 3) {
      return 'Nombre debe tener mínimo 3 caracteres';
    }
    
    if (trimmed.length > 30) {
      return 'Nombre no puede exceder 30 caracteres (actual: ${trimmed.length})';
    }
    
    // Solo letras, números limitados y espacios
    if (!RegExp(r'^[a-záéíóúñA-ZÁÉÍÓÚÑ\s&\-\.]+$').hasMatch(trimmed)) {
      return 'Nombre contiene caracteres no permitidos';
    }
    
    return null;
  }

  /// Valida código de servicio (solo letras y números, max 7 caracteres)
  static String? validateServiceCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Código es requerido';
    }
    
    final trimmed = value.trim().toUpperCase();
    
    if (trimmed.length < 2) {
      return 'Código debe tener mínimo 2 caracteres';
    }
    
    if (trimmed.length > 7) {
      return 'Código no puede exceder 7 caracteres (actual: ${trimmed.length})';
    }
    
    // Solo letras y números
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(trimmed)) {
      return 'Código solo puede contener letras y números';
    }
    
    return null;
  }

  /// Valida precio (solo números, mayor a 0)
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Precio es requerido';
    }
    
    final price = double.tryParse(value);
    
    if (price == null) {
      return 'Precio debe ser un número válido';
    }
    
    if (price <= 0) {
      return 'Precio debe ser mayor a 0';
    }
    
    if (price > 999999.99) {
      return 'Precio es demasiado alto';
    }
    
    return null;
  }

  /// Valida duración (solo números, entre 5 y 480 minutos)
  static String? validateDuration(String? value) {
    if (value == null || value.isEmpty) {
      return 'Duración es requerida';
    }
    
    final duration = int.tryParse(value);
    
    if (duration == null) {
      return 'Duración debe ser un número entero válido';
    }
    
    if (duration < 5) {
      return 'Duración mínima es 5 minutos';
    }
    
    if (duration > 480) {
      return 'Duración máxima es 480 minutos (8 horas)';
    }
    
    return null;
  }

  /// Valida descripción (opcional, max 500 caracteres)
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Opcional
    }
    
    if (value.length > 500) {
      return 'Descripción no puede exceder 500 caracteres (actual: ${value.length})';
    }
    
    return null;
  }

  /// Valida email (estructura real)
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email es requerido';
    }
    
    value = value.trim();
    
    // Regex más estricto para emails reales
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9][a-zA-Z0-9._%-]*@[a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    
    // Validar que no sea un email trivial (a@a.com, test@test.com, etc)
    final parts = value.split('@');
    final localPart = parts[0];
    final domain = parts[1].split('.')[0];
    
    if (localPart.length < 3) {
      return 'Email: la parte antes de @ debe tener mínimo 3 caracteres';
    }
    
    if (localPart == domain) {
      return 'Email: debe ser una dirección válida';
    }
    
    return null;
  }

  /// Valida teléfono (debe empezar con 09 y tener exactamente 10 dígitos)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Teléfono es requerido';
    }
    
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length != 10) {
      return 'Teléfono debe tener exactamente 10 dígitos';
    }
    
    if (!digitsOnly.startsWith('09')) {
      return 'Teléfono debe empezar con 09';
    }
    
    return null;
  }

  /// Valida contraseña (min 8 caracteres, mayúscula, minúscula, número y carácter especial)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contraseña es requerida';
    }
    
    if (value.length < 8) {
      return 'Contraseña debe tener mínimo 8 caracteres';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Contraseña debe contener números';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Contraseña debe contener letras minúsculas';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Contraseña debe contener letras mayúsculas';
    }
    
    if (!RegExp(r'[.#$%&@!*\-_=+]').hasMatch(value)) {
      return 'Contraseña debe contener un carácter especial (.#\$%&@!*-_=+)';
    }
    
    return null;
  }

  /// Valida que dos contraseñas coincidan
  static String? validatePasswordMatch(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Debe confirmar la contraseña';
    }
    
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    
    return null;
  }

  /// Valida especialidad (min 3 letras)
  static String? validateSpecialty(String? value) {
    if (value == null || value.isEmpty) {
      return 'Especialidad es requerida';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 3) {
      return 'Especialidad debe tener mínimo 3 caracteres';
    }
    
    if (trimmed.length > 50) {
      return 'Especialidad no puede exceder 50 caracteres';
    }
    
    return null;
  }

  /// Valida calificación (entre 0 y 5 estrellas)
  static String? validateRating(String? value) {
    if (value == null || value.isEmpty) {
      return 'Calificación es requerida';
    }
    
    final rating = double.tryParse(value);
    
    if (rating == null) {
      return 'Calificación debe ser un número válido';
    }
    
    if (rating < 0 || rating > 5) {
      return 'Calificación debe estar entre 0 y 5';
    }
    
    return null;
  }

  /// Obtiene todos los campos vacíos de un mapa
  static List<String> getEmptyRequiredFields(Map<String, dynamic> fields) {
    final emptyFields = <String>[];
    
    fields.forEach((key, value) {
      if (value == null || (value is String && value.trim().isEmpty)) {
        emptyFields.add(key);
      }
    });
    
    return emptyFields;
  }
}
