import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  Future<http.Response> post(String path, {Map<String, String>? body, Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl$path');
    return await http.post(url, body: body, headers: headers);
  }
  // Puedes agregar métodos get, put, delete, etc. aquí
}
