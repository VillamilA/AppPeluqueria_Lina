import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CatalogApi {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  Future<List<dynamic>> getCatalogs(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v1/catalog'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map && data.containsKey('data')) {
        return data['data'] as List<dynamic>;
      }
      return data is List ? data : [];
    }
    throw Exception('Error al obtener catálogos');
  }

  Future getCatalogById(String id, String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v1/catalog/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map && data.containsKey('data')) {
        return (data['data'] as List).isNotEmpty ? data['data'][0] : null;
      }
      return data is Map ? data : null;
    }
    return null;
  }
}
