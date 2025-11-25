class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<void> register(Map<String, dynamic> data) async {
    // TODO: Implementar llamada a la API usando variables de entorno
    // Por ahora simula un registro exitoso
    await Future.delayed(const Duration(seconds: 1));
    // Si hay error, lanza una excepción
    // throw Exception('Error en el registro');
  }
}
