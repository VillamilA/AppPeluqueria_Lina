class EmailService {
  EmailService._();
  static final EmailService instance = EmailService._();

  Future<void> sendVerificationEmail(String email) async {
    // TODO: Implementar envío de email de verificación
    await Future.delayed(const Duration(seconds: 1));
    // Si hay error, lanza una excepción
    // throw Exception('No se pudo enviar el correo');
  }
}
