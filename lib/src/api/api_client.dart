import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  Future<http.Response> post(String path, {dynamic body, Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl$path');
    if (body != null && body is! String) {
      headers = {...?headers, 'Content-Type': 'application/json'};
      final jsonBody = body is Map ? jsonEncode(body) : body.toString();
      return await http.post(url, body: jsonBody, headers: headers);
    }
    return await http.post(url, body: body, headers: headers);
  }

  Future<http.Response> get(String path, {Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl$path');
    return await http.get(url, headers: headers);
  }

  Future<http.Response> put(String path, {dynamic body, Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl$path');
    if (body != null && body is! String) {
      headers = {...?headers, 'Content-Type': 'application/json'};
      final jsonBody = body is Map ? jsonEncode(body) : body.toString();
      return await http.put(url, body: jsonBody, headers: headers);
    }
    return await http.put(url, body: body, headers: headers);
  }

  Future<http.Response> delete(String path, {Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl$path');
    return await http.delete(url, headers: headers);
  }
}
