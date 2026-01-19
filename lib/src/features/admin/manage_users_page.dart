import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../api/users_api.dart';
import '../../api/api_client.dart';
import '../../widgets/search_bar_widget.dart';

class ManageUsersPage extends StatefulWidget {
  final String token;
  final String userRole; // ADMIN, GERENTE

  const ManageUsersPage({
    super.key,
    required this.token,
    required this.userRole,
  });

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  late UsersApi _usersApi;
  final TextEditingController _searchController = TextEditingController();

  // Datos
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];

  // Filtros
  String filterStatus = 'ALL'; // ALL, ACTIVE, INACTIVE
  String filterRole = 'ALL'; // ALL, CLIENTE, ESTILISTA, ADMIN, GERENTE
  String searchQuery = '';

  // Estados
  bool loading = false;

  // Estadísticas
  int totalUsers = 0;
  int activeUsers = 0;
  int inactiveUsers = 0;

  @override
  void initState() {
    super.initState();
    _usersApi = UsersApi(ApiClient.instance);
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => loading = true);

      final res = await _usersApi.listAllUsers(
        token: widget.token,
        page: 1,
        limit: 500, // Obtener muchos usuarios
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final users = List<Map<String, dynamic>>.from(data['data'] ?? []);

        print('✅ ${users.length} usuarios cargados');

        setState(() {
          allUsers = users;
          _calculateStats();
          _applyFilters();
        });
      } else {
        print('❌ Error: ${res.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar usuarios')),
          );
        }
      }
    } catch (e) {
      print('❌ Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _calculateStats() {
    totalUsers = allUsers.length;
    activeUsers = allUsers.where((u) => u['isActive'] == true).length;
    inactiveUsers = allUsers.where((u) => u['isActive'] == false).length;

    print('📊 Estadísticas: Total=$totalUsers, Activos=$activeUsers, Inactivos=$inactiveUsers');
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = allUsers;

    // Filtro por estado
    if (filterStatus == 'ACTIVE') {
      filtered = filtered.where((u) => u['isActive'] == true).toList();
    } else if (filterStatus == 'INACTIVE') {
      filtered = filtered.where((u) => u['isActive'] == false).toList();
    }

    // Filtro por rol
    if (filterRole != 'ALL') {
      filtered = filtered.where((u) => u['role'] == filterRole).toList();
    }

    // Búsqueda
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((u) {
        final nombre = (u['nombre'] ?? '').toString().toLowerCase();
        final apellido = (u['apellido'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return nombre.contains(q) || apellido.contains(q) || email.contains(q);
      }).toList();
    }

    setState(() {
      filteredUsers = filtered;
    });

    print('🔍 Filtrados: ${filteredUsers.length} usuarios');
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final userId = user['_id'] ?? '';
    final currentStatus = user['isActive'] ?? true;
    final newStatus = !currentStatus;

    try {
      setState(() => loading = true);

      final res = currentStatus
          ? await _usersApi.deactivateUser(
              userId,
              token: widget.token,
            )
          : await _usersApi.activateUser(
              userId,
              token: widget.token,
            );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? '✅ Usuario ${user['nombre']} activado'
                  : '❌ Usuario ${user['nombre']} desactivado',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );

        // Recargar usuarios
        await _loadUsers();
      } else {
        throw Exception('Error: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return '-';
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.red;
      case 'GERENTE':
        return Colors.purple;
      case 'ESTILISTA':
        return Colors.blue;
      case 'CLIENTE':
        return Colors.green;
      default:
        return AppColors.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: Text(
          'Usuarios',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.gold),
        toolbarHeight: 70,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Icon(Icons.refresh, color: AppColors.gold),
              onPressed: _loadUsers,
              tooltip: 'Actualizar',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(130),
          child: Column(
            children: [
              SizedBox(height: 2),
              // Estadísticas
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatChip(
                        'Total',
                        totalUsers.toString(),
                        Icons.people,
                        AppColors.gold,
                      ),
                      SizedBox(width: 16),
                      _buildStatChip(
                        'Activos',
                        activeUsers.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      SizedBox(width: 16),
                      _buildStatChip(
                        'Inactivos',
                        inactiveUsers.toString(),
                        Icons.cancel,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 6),
              // Filtros por estado y rol
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Estado
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.gray.withOpacity(0.3)),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          underline: SizedBox(),
                          value: filterStatus,
                          items: [
                            DropdownMenuItem(
                              value: 'ALL',
                              child: Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Text('Todos', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ACTIVE',
                              child: Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Text('Activos', style: TextStyle(color: Colors.green)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'INACTIVE',
                              child: Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Text('Inactivos', style: TextStyle(color: Colors.red)),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              filterStatus = value ?? 'ALL';
                              _applyFilters();
                            });
                          },
                          dropdownColor: AppColors.charcoal,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Rol
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.gray.withOpacity(0.3)),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          underline: SizedBox(),
                          value: filterRole,
                          items: [
                            DropdownMenuItem(
                              value: 'ALL',
                              child: Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Text('Todos', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'CLIENTE',
                              child: Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Text('Clientes', style: TextStyle(color: Colors.green)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ESTILISTA',
                              child: Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Text('Estilistas', style: TextStyle(color: Colors.blue)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'GERENTE',
                              child: Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Text('Gerentes', style: TextStyle(color: Colors.purple)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ADMIN',
                              child: Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Text('Admins', style: TextStyle(color: Colors.red)),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              filterRole = value ?? 'ALL';
                              _applyFilters();
                            });
                          },
                          dropdownColor: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Búsqueda
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black26,
              border: Border(
                bottom: BorderSide(color: AppColors.gray.withOpacity(0.3)),
              ),
            ),
            child: SearchBarWidget(
              controller: _searchController,
              placeholder: 'Buscar por nombre, apellido o email...',
              onSearch: (query) {
                setState(() {
                  searchQuery = query;
                  _applyFilters();
                });
              },
            ),
          ),
          // Lista de usuarios
          Expanded(
            child: loading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  )
                : filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: AppColors.gray),
                            SizedBox(height: 16),
                            Text(
                              'No hay usuarios',
                              style: TextStyle(color: AppColors.gray, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(16),
                        separatorBuilder: (_, __) => SizedBox(height: 12),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final isActive = user['isActive'] ?? true;
                          final nombre = user['nombre'] ?? 'N/A';
                          final apellido = user['apellido'] ?? '';
                          final email = user['email'] ?? 'N/A';
                          final role = user['role'] ?? 'N/A';
                          final lastLogin = _formatDate(user['lastLoginAt']);
                          final verified = user['emailVerified'] ?? false;

                          return Card(
                            margin: EdgeInsets.zero,
                            color: Color(0xFF2A2A2A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isActive
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header: Nombre y Estado
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$nombre $apellido',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              email,
                                              style: TextStyle(
                                                color: AppColors.gray,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          // Estado
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? Colors.green.withOpacity(0.2)
                                                  : Colors.red.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isActive ? Colors.green : Colors.red,
                                              ),
                                            ),
                                            child: Text(
                                              isActive ? '✅ Activo' : '❌ Inactivo',
                                              style: TextStyle(
                                                color: isActive ? Colors.green : Colors.red,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          // Rol
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getRoleColor(role).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              role,
                                              style: TextStyle(
                                                color: _getRoleColor(role),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  // Info adicional
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Último acceso',
                                              style: TextStyle(
                                                color: AppColors.gray,
                                                fontSize: 11,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              lastLogin,
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: verified ? Colors.blue.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          verified ? '✓ Verificado' : '⚠ No verificado',
                                          style: TextStyle(
                                            color: verified ? Colors.blue : Colors.orange,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  // Botón de acción
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _toggleUserStatus(user),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isActive ? Colors.red : Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        isActive ? '🔴 Suspender Acceso' : '🟢 Habilitar Acceso',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.gray,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
