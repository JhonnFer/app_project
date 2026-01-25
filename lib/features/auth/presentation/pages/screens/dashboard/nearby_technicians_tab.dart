import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../data/datasources/location_service.dart';
import '../../../../domain/entities/location.dart';
import '../../../../domain/entities/technician_location.dart';

class NearbyTechniciansTab extends StatefulWidget {
  final bool allowSelection;
  final int maxSelection;

  const NearbyTechniciansTab({
    Key? key,
    this.allowSelection = false,
    this.maxSelection = 2,
  }) : super(key: key);

  @override
  State<NearbyTechniciansTab> createState() => _NearbyTechniciansTabState();
}

class _NearbyTechniciansTabState extends State<NearbyTechniciansTab> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  LocationData? _currentLocation;
  List<TechnicianLocation> _nearbyTechnicians = [];
  Set<String> _selectedTechnicianIds = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      print('=== INICIALIZANDO TAB DE TÉCNICOS ===');
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      /// 📍 1. OBTENER UBICACIÓN ACTUAL
      LocationData location;

      try {
        print('📍 Obteniendo ubicación actual...');
        final position = await _locationService.getCurrentPosition();

        location = LocationData(
          userId: 'default', // 🔴 luego se reemplaza por user real
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          address: 'Ubicación actual',
          timestamp: DateTime.now(),
        );
        print(
            '✅ Ubicación obtenida: ${location.latitude}, ${location.longitude}');
      } catch (_) {
        print('⚠️ Error obteniendo ubicación GPS');

        /// Fallback si falla GPS
        location = LocationData(
          userId: 'default',
          latitude: -0.180653,
          longitude: -78.467834, // Quito
          accuracy: 0,
          address: 'Ubicación predeterminada',
          timestamp: DateTime.now(),
        );
        print('ℹ️ Usando ubicación predeterminada: Quito');
      }

      _currentLocation = location;

      /// 👨‍🔧 2. OBTENER TÉCNICOS
      print('👨‍🔧 Buscando técnicos cercanos...');
      _nearbyTechnicians = await _fetchNearbyTechniciansFromFirebase(location);

      if (_nearbyTechnicians.isEmpty) {
        print(
            'ℹ️ No se encontraron técnicos en Firebase, usando técnicos de prueba');
        _nearbyTechnicians = _generateMockTechnicians(location);
      }

      setState(() => _isLoading = false);

      // 🗺️ Mover el mapa después de que se actualice el estado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          LatLng(location.latitude, location.longitude),
          13,
        );
      });

      print('✅ Tab de técnicos cargada correctamente');
    } catch (e) {
      print('❌ Error al inicializar tab: $e');
      setState(() {
        _errorMessage = 'Error al cargar técnicos';
        _isLoading = false;
      });
    }
  }

  /// 🔥 FIREBASE
  Future<List<TechnicianLocation>> _fetchNearbyTechniciansFromFirebase(
      LocationData userLocation) async {
    try {
      print('🔍 Buscando técnicos en Firebase...');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'technician')
          .get();

      print('✅ Se encontraron ${snapshot.docs.length} técnicos');

      final List<TechnicianLocation> technicians = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        print('👨‍🔧 Técnico encontrado: ${data['name']} (${doc.id})');
        print('   Lat: ${data['latitude']}, Lng: ${data['longitude']}');

        // 🔧 Convertir coordenadas de Firebase (num) a double
        double techLat = userLocation.latitude;
        double techLng = userLocation.longitude;

        if (data['latitude'] != null) {
          techLat = (data['latitude'] as num).toDouble();
        }
        if (data['longitude'] != null) {
          techLng = (data['longitude'] as num).toDouble();
        }

        final techLocation = LocationData(
          userId: doc.id,
          latitude: techLat,
          longitude: techLng,
          accuracy: 5,
          address: data['address'] ?? 'Ubicación desconocida',
          timestamp: DateTime.now(),
        );

        final distance = TechnicianLocation.calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          techLocation.latitude,
          techLocation.longitude,
        );

        technicians.add(
          TechnicianLocation(
            id: doc.id,
            name: data['name'] ?? 'Técnico',
            profileImage:
                data['profileImage'] ?? 'https://via.placeholder.com/150',
            rating: (data['rating'] ?? 0).toDouble(),
            completedServices: data['completedServices'] ?? 0,
            location: techLocation,
            services: List<String>.from(data['specialties'] ?? const []),
            isOnline: data['isAvailable'] ?? true,
            distanceKm: distance,
          ),
        );
      }

      technicians.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      print('✅ Total técnicos cargados: ${technicians.length}');
      return technicians;
    } catch (e) {
      print('❌ Error al buscar técnicos en Firebase: $e');
      return [];
    }
  }

  /// 🧪 MOCK
  List<TechnicianLocation> _generateMockTechnicians(LocationData userLocation) {
    return [
      TechnicianLocation(
        id: '1',
        name: 'Carlos García',
        profileImage: 'https://via.placeholder.com/150',
        rating: 4.8,
        completedServices: 120,
        location: LocationData(
          userId: '1',
          latitude: userLocation.latitude + 0.004,
          longitude: userLocation.longitude + 0.003,
          accuracy: 5,
          address: 'Centro',
          timestamp: DateTime.now(),
        ),
        services: ['Lavadoras', 'Refrigeradores'],
        isOnline: true,
        distanceKm: 0.7,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    return Stack(
      children: [
        // Mapa
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
            ),
            initialZoom: 13,
            onTap: (tapPosition, point) {
              // Detectar tap en marcadores
              for (final tech in _nearbyTechnicians) {
                final techPoint = LatLng(
                  tech.location.latitude,
                  tech.location.longitude,
                );
                
                // Distancia aproximada en pixels
                if (_distanceBetweenPoints(point, techPoint) < 0.002) {
                  _toggleTechnicianSelection(tech.id);
                  break;
                }
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.app.project',
            ),
            MarkerLayer(
              markers: [
                /// 📍 Usuario
                Marker(
                  point: LatLng(
                    _currentLocation!.latitude,
                    _currentLocation!.longitude,
                  ),
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.my_location,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),

                /// 👨‍🔧 Técnicos
                ..._nearbyTechnicians.map(
                  (tech) {
                    final isSelected = _selectedTechnicianIds.contains(tech.id);
                    
                    return Marker(
                      point: LatLng(
                        tech.location.latitude,
                        tech.location.longitude,
                      ),
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _toggleTechnicianSelection(tech.id),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.white,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person_pin_circle,
                            color: isSelected
                                ? Colors.blue
                                : (tech.isOnline
                                    ? AppColors.success
                                    : AppColors.grey400),
                            size: 40,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // Si es selección, mostrar panel inferior
        if (widget.allowSelection)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info de selección
                  Text(
                    'Selecciona técnicos (${_selectedTechnicianIds.length}/${widget.maxSelection})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  // Lista de técnicos seleccionados
                  if (_selectedTechnicianIds.isNotEmpty)
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedTechnicianIds.length,
                        itemBuilder: (context, index) {
                          final techId =
                              _selectedTechnicianIds.toList()[index];
                          final tech = _nearbyTechnicians
                              .firstWhere((t) => t.id == techId);

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.blue,
                                          width: 2,
                                        ),
                                        color: Colors.blue.withOpacity(0.1),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    Positioned(
                                      top: -8,
                                      right: -8,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedTechnicianIds
                                                .remove(techId);
                                          });
                                        },
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.red,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    tech.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _selectedTechnicianIds.isEmpty
                                  ? null
                                  : () {
                                      // Retornar técnicos seleccionados
                                      final selectedTechs =
                                          _nearbyTechnicians
                                              .where((t) =>
                                                  _selectedTechnicianIds
                                                      .contains(t.id))
                                              .toList();

                                      final result = selectedTechs
                                          .map((t) => {
                                                'id': t.id,
                                                'name': t.name,
                                                'distance':
                                                    t.distanceKm,
                                                'rating': t.rating,
                                              })
                                          .toList();

                                      Navigator.pop(context, result);
                                    },
                          child: Text(
                              'Confirmar (${_selectedTechnicianIds.length})'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Helper: Distancia entre dos puntos
  double _distanceBetweenPoints(LatLng p1, LatLng p2) {
    return ((p1.latitude - p2.latitude) * (p1.latitude - p2.latitude) +
            (p1.longitude - p2.longitude) * (p1.longitude - p2.longitude))
        .toDouble();
  }

  /// Toggle selección de técnico
  void _toggleTechnicianSelection(String technicianId) {
    if (!widget.allowSelection) return;

    setState(() {
      if (_selectedTechnicianIds.contains(technicianId)) {
        _selectedTechnicianIds.remove(technicianId);
      } else {
        if (_selectedTechnicianIds.length < widget.maxSelection) {
          _selectedTechnicianIds.add(technicianId);
        }
      }
    });
  }
}