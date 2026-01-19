/// Validadores para formularios de la aplicación
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

  /// Valida email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email es requerido';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    
    return null;
  }

  /// Valida teléfono (solo números, min 7 dígitos)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Teléfono es requerido';
    }
    
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length < 7) {
      return 'Teléfono debe tener al menos 7 dígitos';
    }
    
    if (digitsOnly.length > 15) {
      return 'Teléfono es muy largo';
    }
    
    return null;
  }

  /// Valida contraseña (min 6 caracteres, debe tener letras y números)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contraseña es requerida';
    }
    
    if (value.length < 6) {
      return 'Contraseña debe tener mínimo 6 caracteres';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Contraseña debe contener números';
    }
    
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Contraseña debe contener letras';
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
