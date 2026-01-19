import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/business_hours_service.dart';

/// Widget que muestra la ubicación de Peluquería Lina con mapa interactivo
class LocationCard extends StatefulWidget {
  final bool isCompact;

  const LocationCard({super.key, this.isCompact = false});

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  // Coordenadas de Peluquería Lina en Quito
  static const double _peluqueriaLat = -0.11113829591886032;
  static const double _peluqueriaLng = -78.4941539986152;
  final LatLng _peluqueriaLocation = const LatLng(_peluqueriaLat, _peluqueriaLng);

  Position? _userPosition;
  double? _distanceInKm;
  bool _loadingLocation = false;
  String? _locationError;
  
  Map<int, BusinessHours>? _businessHours;
  bool _loadingBusinessHours = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadBusinessHours();
  }

  Future<void> _loadBusinessHours() async {
    setState(() {
      _loadingBusinessHours = true;
    });

    try {
      print('🕐 [LocationCard] Cargando horarios del negocio...');
      final service = BusinessHoursService();
      service.initialize();
      final hours = await service.getBusinessHours();
      
      print('🕐 [LocationCard] Horarios cargados: ${hours.length} días');
      hours.forEach((day, hour) {
        print('🕐 [LocationCard] Día $day: ${hour.openTime} - ${hour.closeTime}');
      });
      
      setState(() {
        _businessHours = hours;
        _loadingBusinessHours = false;
      });
    } catch (e) {
      print('❌ [LocationCard] Error cargando horarios del negocio: $e');
      setState(() {
        _loadingBusinessHours = false;
      });
    }
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Servicio de ubicación deshabilitado';
          _loadingLocation = false;
        });
        return;
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Permiso de ubicación denegado';
            _loadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Permisos denegados permanentemente';
          _loadingLocation = false;
        });
        return;
      }

      // Obtener ubicación
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // Calcular distancia
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _peluqueriaLat,
        _peluqueriaLng,
      );

      setState(() {
        _userPosition = position;
        _distanceInKm = distance / 1000;
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Error al obtener ubicación';
        _loadingLocation = false;
      });
    }
  }

  Future<void> _openInGoogleMaps() async {
    final url = Uri.parse('https://maps.app.goo.gl/C1LTfwizrodQZXjX6');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openDirections() async {
    String urlString;
    if (_userPosition != null) {
      // Con ubicación del usuario
      urlString = 'https://www.google.com/maps/dir/${_userPosition!.latitude},${_userPosition!.longitude}/-0.11113829591886032,-78.4941539986152';
    } else {
      // Sin ubicación, solo muestra el destino
      urlString = 'https://maps.app.goo.gl/C1LTfwizrodQZXjX6';
    }

    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Widget> _buildBusinessHoursRows() {
    if (_businessHours == null || _businessHours!.isEmpty) {
      return [];
    }

    final dayNames = {
      0: 'Lun',
      1: 'Mar',
      2: 'Mié',
      3: 'Jue',
      4: 'Vie',
      5: 'Sáb',
      6: 'Dom',
    };

    List<Widget> rows = [];
    
    // Ordenar por día de la semana (0 = Lunes, 6 = Domingo)
    final sortedDays = _businessHours!.keys.toList()..sort();
    
    for (var dayOfWeek in sortedDays) {
      final hours = _businessHours![dayOfWeek]!;
      
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  dayNames[dayOfWeek] ?? 'Día',
                  style: TextStyle(
                    color: AppColors.gray,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${hours.openTime} - ${hours.closeTime}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade900,
            Colors.black87,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.2),
                  AppColors.gold.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.location_on, color: AppColors.gold, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Peluquería Lina',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quito, Ecuador',
                        style: TextStyle(color: AppColors.gray, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Distance badge
                if (_distanceInKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gold.withValues(alpha: 0.3),
                          AppColors.gold.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me, color: AppColors.gold, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${_distanceInKm!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_loadingLocation)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.gold),
                  ),
              ],
            ),
          ),

          // Map
          SizedBox(
            height: widget.isCompact ? 350 : 450,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _peluqueriaLocation,
                      initialZoom: 15.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.peluquerialina.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _peluqueriaLocation,
                            width: 80,
                            height: 80,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.gold,
                                        AppColors.gold.withValues(alpha: 0.7),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gold.withValues(alpha: 0.6),
                                        blurRadius: 15,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.content_cut,
                                    color: Colors.black,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Marcador del usuario
                          if (_userPosition != null)
                            Marker(
                              point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                              width: 60,
                              height: 60,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Círculo pulsante
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  // Marcador principal
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.blue, Colors.blue.shade700],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withValues(alpha: 0.5),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  // Attribution
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '© OpenStreetMap',
                        style: TextStyle(color: AppColors.gray, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Buttons (debajo del mapa)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 8,
                          shadowColor: AppColors.gold.withValues(alpha: 0.4),
                        ),
                        onPressed: _openInGoogleMaps,
                        icon: const Icon(Icons.map, size: 22),
                        label: const Text(
                          'Ver en Maps',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gold,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppColors.gold, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _openDirections,
                        icon: const Icon(Icons.directions, size: 22),
                        label: const Text(
                          'Cómo Llegar',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Info de distancia o error
                if (_locationError != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _locationError!,
                            style: const TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: _getUserLocation,
                          child: const Text(
                            'Reintentar',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Sección de contacto
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.15),
                        AppColors.gold.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: InkWell(
                    onTap: () async {
                      final uri = Uri.parse('tel:+593980865549');
                      try {
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al realizar la llamada'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.phone, color: AppColors.gold, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contacto',
                                style: TextStyle(
                                  color: AppColors.gray,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '+593 98 086 5549',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.gold.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                // Sección de horarios del negocio
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.15),
                        AppColors.gold.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.access_time, color: AppColors.gold, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Horario de Atención',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_loadingBusinessHours)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.gold,
                            ),
                          ),
                        )
                      else if (_businessHours != null && _businessHours!.isNotEmpty)
                        ..._buildBusinessHoursRows()
                      else
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'No hay horarios configurados',
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
