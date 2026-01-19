import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<dynamic> login({required String email, required String password}) async {
    final url = '${dotenv.env['API_BASE_URL']}${dotenv.env['API_LOGIN_PATH']}';
    final response = await http.post(
      Uri.parse(url),
      body: {'email': email, 'password': password},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error en el login: ${response.body}');
    }
  }

  Future<dynamic> register(Map<String, dynamic> data) async {
    final url = '${dotenv.env['API_BASE_URL']}${dotenv.env['API_REGISTER_PATH']}';
    final response = await http.post(
      Uri.parse(url),
      body: data.map((k, v) => MapEntry(k, v.toString())),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final result = json.decode(response.body);
      
      // Enviar email de verificación automáticamente después del registro
      try {
        print('📧 Enviando email de verificación a ${data['email']}...');
        await sendVerificationEmail(data['email']);
        print('✅ Email de verificación enviado correctamente');
      } catch (e) {
        print('⚠️ Error al enviar email de verificación: $e');
        // No lanzamos error para que el registro se complete
      }
      
      return result;
    } else {
      throw Exception('Error en el registro: ${response.body}');
    }
  }

  /// Envía el email de verificación
  Future<void> sendVerificationEmail(String email) async {
    final url = '${dotenv.env['API_BASE_URL']}/api/v1/auth/send-verification-email';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al enviar email de verificación');
    }
  }

  /// Solicita código de recuperación de contraseña
  static Future<void> forgotPassword(String email) async {
    final url = '${dotenv.env['API_BASE_URL']}/api/v1/auth/forgot-password';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      // Código enviado exitosamente
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Usuario no encontrado');
    } else if (response.statusCode == 429) {
      throw Exception('Debes esperar 90 segundos para reenviar el código');
    } else {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Error al solicitar código');
    }
  }

  /// Restablece la contraseña con el código de recuperación
  static Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final url = '${dotenv.env['API_BASE_URL']}/api/v1/auth/reset-password';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'code': code,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      // Contraseña actualizada exitosamente
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Usuario no encontrado');
    } else if (response.statusCode == 400) {
      final body = json.decode(response.body);
      final message = body['message'] ?? 'Error al restablecer contraseña';
      
      if (message.contains('expirado')) {
        throw Exception('Código expirado. Solicita uno nuevo.');
      } else if (message.contains('incorrecto')) {
        throw Exception('Código incorrecto');
      } else if (message.contains('contraseña')) {
        throw Exception('La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número');
      }
      
      throw Exception(message);
    } else {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Error al restablecer contraseña');
    }
  }
}