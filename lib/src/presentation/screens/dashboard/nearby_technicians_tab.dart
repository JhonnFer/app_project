import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/location_service.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/entities/technician_location.dart';

class NearbyTechniciansTab extends StatefulWidget {
  const NearbyTechniciansTab({Key? key}) : super(key: key);

  @override
  State<NearbyTechniciansTab> createState() => _NearbyTechniciansTabState();
}

class _NearbyTechniciansTabState extends State<NearbyTechniciansTab> {
  late LocationService _locationService;
  LocationData? _currentLocation;
  bool _isLoading = true;
  String? _errorMessage;
  final MapController _mapController = MapController();
  List<TechnicianLocation> _nearbyTechnicians = [];

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      setState(() => _isLoading = true);
      
      // Obtener ubicación actual con timeout personalizado
      LocationData location;
      try {
        location = await _locationService.getCurrentLocation();
      } catch (e) {
        // Si falla o tarda demasiado, usar ubicación por defecto (Bogotá)
        location = LocationData(
          latitude: 4.7110,
          longitude: -74.0055,
          accuracy: 0.0,
          address: 'Ubicación predeterminada (Bogotá)',
          timestamp: DateTime.now(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usando ubicación predeterminada'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      setState(() => _currentLocation = location);
      
      // Simular técnicos cercanos
      _nearbyTechnicians = _generateMockTechnicians(location);
      
      setState(() => _isLoading = false);
      
      // Centrar el mapa en la ubicación actual
      _mapController.move(
        LatLng(location.latitude, location.longitude),
        13.0,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<TechnicianLocation> _generateMockTechnicians(LocationData userLocation) {
    // Datos simulados de técnicos cercanos
    final mockTechnicians = [
      TechnicianLocation(
        id: '1',
        name: 'Carlos García',
        profileImage: 'https://via.placeholder.com/150',
        rating: 4.8,
        completedServices: 156,
        location: LocationData(
          latitude: userLocation.latitude + 0.005,
          longitude: userLocation.longitude + 0.003,
          accuracy: 5.0,
          address: 'Cerca de Plaza Mayor',
          timestamp: DateTime.now(),
        ),
        services: ['Refrigerador', 'Lavadora', 'Microondas'],
        isOnline: true,
        distanceKm: 0.75,
      ),
      TechnicianLocation(
        id: '2',
        name: 'María López',
        profileImage: 'https://via.placeholder.com/150',
        rating: 4.9,
        completedServices: 203,
        location: LocationData(
          latitude: userLocation.latitude - 0.004,
          longitude: userLocation.longitude + 0.006,
          accuracy: 5.0,
          address: 'Centro Comercial',
          timestamp: DateTime.now(),
        ),
        services: ['Horno', 'Secadora', 'Refrigerador'],
        isOnline: true,
        distanceKm: 1.2,
      ),
      TechnicianLocation(
        id: '3',
        name: 'Pedro Martínez',
        profileImage: 'https://via.placeholder.com/150',
        rating: 4.6,
        completedServices: 89,
        location: LocationData(
          latitude: userLocation.latitude + 0.008,
          longitude: userLocation.longitude - 0.004,
          accuracy: 5.0,
          address: 'Av. Principal',
          timestamp: DateTime.now(),
        ),
        services: ['Lavadora', 'Aire Acondicionado'],
        isOnline: false,
        distanceKm: 1.8,
      ),
      TechnicianLocation(
        id: '4',
        name: 'Ana Rodríguez',
        profileImage: 'https://via.placeholder.com/150',
        rating: 4.7,
        completedServices: 142,
        location: LocationData(
          latitude: userLocation.latitude - 0.006,
          longitude: userLocation.longitude - 0.005,
          accuracy: 5.0,
          address: 'Zona Residencial',
          timestamp: DateTime.now(),
        ),
        services: ['Refrigerador', 'Congelador', 'Horno'],
        isOnline: true,
        distanceKm: 1.45,
      ),
    ];
    
    // Ordenar por distancia
    mockTechnicians.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return mockTechnicians;
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 80, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(_errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initializeData,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          _currentLocation!.latitude,
                          _currentLocation!.longitude,
                        ),
                        initialZoom: 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.techserve.app',
                        ),
                        MarkerLayer(
                          markers: [
                            // Marcador del usuario
                            Marker(
                              point: LatLng(
                                _currentLocation!.latitude,
                                _currentLocation!.longitude,
                              ),
                              width: 60,
                              height: 60,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                            // Marcadores de técnicos
                            ..._nearbyTechnicians.map(
                              (tech) => Marker(
                                point: LatLng(
                                  tech.location.latitude,
                                  tech.location.longitude,
                                ),
                                width: 60,
                                height: 60,
                                child: GestureDetector(
                                  onTap: () => _showTechnicianDetails(tech),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: tech.isOnline
                                          ? AppColors.success
                                          : AppColors.grey400,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: AppColors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        itemCount: _nearbyTechnicians.length,
                        itemBuilder: (context, index) {
                          final tech = _nearbyTechnicians[index];
                          return _buildTechnicianCard(tech);
                        },
                      ),
                    ),
                  ),
                ],
              );
  }

  Widget _buildTechnicianCard(TechnicianLocation technician) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.grey200,
              child: Icon(
                Icons.person,
                color: AppColors.primary,
              ),
            ),
            if (technician.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          technician.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${technician.rating} (${technician.completedServices} servicios)'),
              ],
            ),
            Text(
              '${technician.distanceKm.toStringAsFixed(1)} km',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        trailing: ElevatedButton.icon(
          onPressed: () => _showTechnicianDetails(technician),
          icon: const Icon(Icons.info_outline, size: 16),
          label: const Text('Ver'),
        ),
      ),
    );
  }

  void _showTechnicianDetails(TechnicianLocation technician) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              technician.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text('${technician.rating} - ${technician.completedServices} servicios'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('${technician.distanceKm.toStringAsFixed(1)} km'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Servicios:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: technician.services
                  .map(
                    (service) => Chip(
                      label: Text(service),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Contactando a ${technician.name}...'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Solicitar Servicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
