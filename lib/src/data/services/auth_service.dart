import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<dynamic> login({required String email, required String password}) async {
    final url = '${dotenv.env['API_BASE_URL']}${dotenv.env['API_LOGIN_PATH']}';
    final response = await http.post(
      Uri.parse(url),
      body: {'email': email, 'password': password},
    );
    // Procesa la respuesta y retorna los datos
  }
}