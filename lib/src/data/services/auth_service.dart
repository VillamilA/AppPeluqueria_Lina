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
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error en el registro: ${response.body}');
    }
  }
}