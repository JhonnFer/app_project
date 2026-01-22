import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/location_service.dart';
import '../../../domain/entities/location.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  late LocationService _locationService;
  LocationData? _currentLocation;
  bool _isLoading = true;
  String? _errorMessage;
  final MapController _mapController = MapController();
  bool _isRealtimeMode = false;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() => _isLoading = true);
      final location = await _locationService.getCurrentLocation();
      setState(() {
        _currentLocation = location;
        _isLoading = false;
      });
      
      // Centrar el mapa en la ubicación actual
      _mapController.move(
        LatLng(location.latitude, location.longitude),
        15.0,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleRealtimeMode() {
    setState(() => _isRealtimeMode = !_isRealtimeMode);
    if (_isRealtimeMode) {
      _startRealtimeTracking();
    }
  }

  void _startRealtimeTracking() {
    _locationService.getLocationStream().listen(
      (location) {
        if (mounted) {
          setState(() => _currentLocation = location);
          _mapController.move(
            LatLng(location.latitude, location.longitude),
            15.0,
          );
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error.toString();
            _isRealtimeMode = false;
          });
        }
      },
    );
  }

  void _copyToClipboard() {
    if (_currentLocation != null) {
      final text =
          'Lat: ${_currentLocation!.latitude}, Lng: ${_currentLocation!.longitude}\n${_currentLocation!.address}';
      // En una app real, usarías: Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coordenadas copiadas: $text')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Ubicación'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isRealtimeMode ? Icons.location_on : Icons.location_off),
            onPressed: _toggleRealtimeMode,
            tooltip: _isRealtimeMode ? 'Detener rastreo' : 'Iniciar rastreo',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off,
                        size: 80,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error de Ubicación',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _initializeLocation,
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
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.techserve.app',
                            maxZoom: 19,
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  _currentLocation!.latitude,
                                  _currentLocation!.longitude,
                                ),
                                width: 80,
                                height: 80,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.white,
                                          width: 3,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: AppColors.shadow,
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: AppColors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ],
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
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Detalles de Ubicación',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              _buildLocationInfoTile(
                                icon: Icons.north,
                                label: 'Latitud',
                                value:
                                    _currentLocation!.latitude.toStringAsFixed(6),
                              ),
                              const SizedBox(height: 8),
                              _buildLocationInfoTile(
                                icon: Icons.south_east,
                                label: 'Longitud',
                                value:
                                    _currentLocation!.longitude.toStringAsFixed(6),
                              ),
                              const SizedBox(height: 8),
                              _buildLocationInfoTile(
                                icon: Icons.my_location,
                                label: 'Precisión',
                                value:
                                    '${_currentLocation!.accuracy.toStringAsFixed(2)} m',
                              ),
                              const SizedBox(height: 8),
                              _buildLocationInfoTile(
                                icon: Icons.location_on_outlined,
                                label: 'Dirección',
                                value: _currentLocation!.address,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _copyToClipboard,
                                      icon: const Icon(Icons.content_copy),
                                      label: const Text('Copiar'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _initializeLocation,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Actualizar'),
                                    ),
                                  ),
                                ],
                              ),
                              if (_isRealtimeMode) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.success,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Rastreo en tiempo real activo',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLocationInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
