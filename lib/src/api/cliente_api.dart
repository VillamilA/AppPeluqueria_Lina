import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_client.dart';

class ClienteApi {
  ClienteApi._();
  static final ClienteApi instance = ClienteApi._();

  String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  // Autenticación y usuario
  Future<dynamic> login(String email, String password) async {
    final path = dotenv.env['API_LOGIN_PATH'] ?? '';
    final response = await ApiClient.instance.post(path, body: {
      'email': email,
      'password': password,
    });
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error en el login: ${response.body}');
    }
  }

  Future<dynamic> register(Map<String, dynamic> data) async {
    final path = dotenv.env['API_REGISTER_PATH'] ?? '';
    final response = await ApiClient.instance.post(path, body: data.map((k, v) => MapEntry(k, v.toString())));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error en el registro: ${response.body}');
    }
  }

  Future<dynamic> sendVerificationEmail(String email) async {
    final path = '/api/v1/auth/send-verification';
    final response = await ApiClient.instance.post(path, body: {'email': email});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al enviar verificación: ${response.body}');
    }
  }

  Future<dynamic> verifyEmail(String code) async {
    final path = '/api/v1/auth/verify-email';
    final response = await ApiClient.instance.post(path, body: {'code': code});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al verificar email: ${response.body}');
    }
  }

  // Bookings (Citas)
  Future<List<dynamic>> getBookings(String status) async {
    final path = '/api/v1/bookings/myclient?status=$status';
    final response = await http.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener citas: ${response.body}');
    }
  }

  Future<dynamic> getBookingDetail(String bookingId) async {
    final path = '/api/v1/bookings/$bookingId';
    final response = await http.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener detalle de cita: ${response.body}');
    }
  }

  Future<dynamic> cancelBooking(String bookingId) async {
    final path = '/api/v1/bookings/$bookingId/cancel';
    final response = await ApiClient.instance.post(path);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cancelar cita: ${response.body}');
    }
  }

  Future<dynamic> createBooking(Map<String, dynamic> data) async {
    final path = '/api/v1/bookings';
    final response = await ApiClient.instance.post(path, body: data.map((k, v) => MapEntry(k, v.toString())));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al crear cita: ${response.body}');
    }
  }
}
