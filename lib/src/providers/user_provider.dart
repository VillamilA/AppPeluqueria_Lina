import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../api/api_client.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String _error = '';

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // Constructor
  UserProvider({UserModel? initialUser}) : _currentUser = initialUser;

  /// ✅ CARGAR PERFIL ACTUAL
  Future<void> loadMyProfile(String token) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      print('📍 Cargando perfil actual...');
      
      final response = await ApiClient.instance.get(
        '/api/v1/users/me',
        token: token,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(data);
        print('✅ Perfil cargado: ${_currentUser!.nombre} ${_currentUser!.apellido}');
      } else if (response.statusCode == 401) {
        _error = 'Token inválido o expirado';
        print('❌ $_error');
      } else {
        _error = 'Error ${response.statusCode} al cargar perfil';
        print('❌ $_error');
      }
    } catch (e) {
      _error = 'Error cargando perfil: $e';
      print('❌ $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ ACTUALIZAR MI PERFIL
  Future<bool> updateMyProfile({
    required String token,
    String? nombre,
    String? apellido,
    String? telefono,
    String? genero,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Validaciones
      if (nombre != null && nombre.length < 2) {
        throw Exception('Nombre debe tener mínimo 2 caracteres');
      }
      if (apellido != null && apellido.length < 2) {
        throw Exception('Apellido debe tener mínimo 2 caracteres');
      }
      if (genero != null && !['M', 'F', 'O'].contains(genero)) {
        throw Exception('Género debe ser M, F u O');
      }

      // Construir body dinámicamente
      final body = <String, dynamic>{};
      if (nombre != null && nombre != _currentUser?.nombre) {
        body['nombre'] = nombre;
      }
      if (apellido != null && apellido != _currentUser?.apellido) {
        body['apellido'] = apellido;
      }
      if (telefono != null && telefono != _currentUser?.telefono) {
        body['telefono'] = telefono;
      }
      if (genero != null && genero != _currentUser?.genero) {
        body['genero'] = genero;
      }

      if (body.isEmpty) {
        _error = 'No hay cambios para guardar';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('📤 Enviando actualización: ${body.keys.toList()}');

      final response = await ApiClient.instance.put(
        '/api/v1/users/me',
        body: body,
        token: token,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ IMPORTANTE: Guardar la respuesta en el state
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(data);
        
        print('✅ Perfil actualizado: ${_currentUser!.nombre} ${_currentUser!.apellido}');
        _error = '';
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        _error = errorData['message'] ?? 'Validación fallida';
        print('❌ Error 400: $_error');
      } else if (response.statusCode == 401) {
        _error = 'Token inválido';
        print('❌ Error 401: $_error');
      } else {
        _error = 'Error ${response.statusCode} al actualizar perfil';
        print('❌ $_error');
        print('📋 Response: ${response.body}');
      }
    } catch (e) {
      _error = 'Error actualizando perfil: $e';
      print('❌ $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// ✅ LOGOUT
  void logout() {
    _currentUser = null;
    _error = '';
    _isLoading = false;
    notifyListeners();
    print('🚪 Usuario desconectado');
  }

  /// ✅ SET USER (para login)
  void setUser(UserModel user) {
    _currentUser = user;
    _error = '';
    notifyListeners();
    print('👤 Usuario establecido: ${user.nombre}');
  }

  /// ✅ ACTUALIZAR TOKEN SI EXPIRÓ
  void clearError() {
    _error = '';
    notifyListeners();
  }
}
