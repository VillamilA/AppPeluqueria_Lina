import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/session_manager.dart';
import '../core/error_handler.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  /// Verifica errores HTTP y maneja los casos 401, 403, 500 globalmente
  Future<void> _checkHttpErrors(http.Response response) async {
    final statusCode = response.statusCode;
    
    print('[API_CLIENT] Response Status Code: $statusCode');
    
    // Manejo de errores globales 401, 403, 500
    if (statusCode == 401 || statusCode == 403 || statusCode == 500) {
      print('[API_CLIENT] Error detectado: $statusCode');
      try {
        final body = jsonDecode(response.body);
        final message = body['message'] ?? body['error'] ?? 'Error $statusCode';
        final errorName = body['name'] ?? '';
        
        print('[API_CLIENT] Mensaje de error: $message');
        print('[API_CLIENT] Nombre de error: $errorName');
        
        // Detectar específicamente TokenExpiredError o jwt expired
        final isTokenExpired = errorName.contains('TokenExpiredError') || 
                             message.contains('jwt expired') ||
                             message.contains('token expired');
        
        if (isTokenExpired) {
          print('[API_CLIENT] ✅ TOKEN EXPIRADO DETECTADO - Mostrando popup de sesión expirada');
          await ErrorHandler().handleTokenExpired();
          return;
        }
        
        await ErrorHandler().handleHttpError(statusCode, message);
      } catch (e) {
        print('[API_CLIENT] Error al parsear JSON: $e');
        // Si no se puede parsear, mostrar error sin mensaje detallado
        await ErrorHandler().handleHttpError(statusCode, null);
      }
      return;
    }
  }

  Future<http.Response> post(String path, {dynamic body, Map<String, String>? headers}) async {
    // Registrar actividad del usuario
    SessionManager().recordActivity();
    
    final url = Uri.parse('$baseUrl$path');
    http.Response response;
    
    if (body != null && body is! String) {
      headers = {...?headers, 'Content-Type': 'application/json'};
      final jsonBody = body is Map ? jsonEncode(body) : body.toString();
      response = await http.post(url, body: jsonBody, headers: headers);
    } else {
      response = await http.post(url, body: body, headers: headers);
    }
    
    await _checkHttpErrors(response);
    return response;
  }

  Future<http.Response> get(String path, {Map<String, String>? headers, String? token}) async {
    // Registrar actividad del usuario
    SessionManager().recordActivity();
    
    final url = Uri.parse('$baseUrl$path');
    
    // Agregar token a headers si se proporciona
    if (token != null && token.isNotEmpty) {
      headers = {...?headers, 'Authorization': 'Bearer $token'};
    }
    
    final response = await http.get(url, headers: headers);
    await _checkHttpErrors(response);
    return response;
  }

  Future<http.Response> put(String path, {dynamic body, Map<String, String>? headers, String? token}) async {
    // Registrar actividad del usuario
    SessionManager().recordActivity();
    
    final url = Uri.parse('$baseUrl$path');
    http.Response response;
    
    // Agregar token a headers si se proporciona
    if (token != null && token.isNotEmpty) {
      headers = {...?headers, 'Authorization': 'Bearer $token'};
    }
    
    if (body != null && body is! String) {
      headers = {...?headers, 'Content-Type': 'application/json'};
      final jsonBody = body is Map ? jsonEncode(body) : body.toString();
      response = await http.put(url, body: jsonBody, headers: headers);
    } else {
      response = await http.put(url, body: body, headers: headers);
    }
    
    await _checkHttpErrors(response);
    return response;
  }

  Future<http.Response> delete(String path, {Map<String, String>? headers}) async {
    // Registrar actividad del usuario
    SessionManager().recordActivity();
    
    final url = Uri.parse('$baseUrl$path');
    final response = await http.delete(url, headers: headers);
    await _checkHttpErrors(response);
    return response;
  }

  Future<http.Response> patch(String path, {dynamic body, Map<String, String>? headers}) async {
    // Registrar actividad del usuario
    SessionManager().recordActivity();
    
    final url = Uri.parse('$baseUrl$path');
    http.Response response;
    
    if (body != null && body is! String) {
      headers = {...?headers, 'Content-Type': 'application/json'};
      final jsonBody = body is Map ? jsonEncode(body) : body.toString();
      response = await http.patch(url, body: jsonBody, headers: headers);
    } else {
      response = await http.patch(url, body: body, headers: headers);
    }
    
    await _checkHttpErrors(response);
    return response;
  }
}
