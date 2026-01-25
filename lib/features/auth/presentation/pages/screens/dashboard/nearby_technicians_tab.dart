import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../data/datasources/location_service.dart';
import '../../../../domain/entities/location.dart';
import '../../../../domain/entities/technician_location.dart';

class NearbyTechniciansTab extends StatefulWidget {
  const NearbyTechniciansTab({Key? key}) : super(key: key);

  @override
  State<NearbyTechniciansTab> createState() => _NearbyTechniciansTabState();
}

class _NearbyTechniciansTabState extends State<NearbyTechniciansTab> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  LocationData? _currentLocation;
  List<TechnicianLocation> _nearbyTechnicians = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      /// 📍 1. OBTENER UBICACIÓN ACTUAL
      LocationData location;

      try {
        final position = await _locationService.getCurrentPosition();

        location = LocationData(
          userId: 'default', // 🔴 luego se reemplaza por user real
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          address: 'Ubicación actual',
          timestamp: DateTime.now(),
        );
      } catch (_) {
        /// Fallback si falla GPS
        location = LocationData(
          userId: 'default',
          latitude: -0.180653,
          longitude: -78.467834, // Quito
          accuracy: 0,
          address: 'Ubicación predeterminada',
          timestamp: DateTime.now(),
        );
      }

      _currentLocation = location;

      /// 👨‍🔧 2. OBTENER TÉCNICOS
      _nearbyTechnicians =
          await _fetchNearbyTechniciansFromFirebase(location);

      if (_nearbyTechnicians.isEmpty) {
        _nearbyTechnicians = _generateMockTechnicians(location);
      }

      _mapController.move(
        LatLng(location.latitude, location.longitude),
        13,
      );

      setState(() => _isLoading = false);
    } catch (e) {
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
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'technician')
          .get();

      final List<TechnicianLocation> technicians = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final techLocation = LocationData(
          userId: doc.id,
          latitude: (data['latitude'] ?? userLocation.latitude).toDouble(),
          longitude: (data['longitude'] ?? userLocation.longitude).toDouble(),
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
            profileImage: data['profileImage'] ??
                'https://via.placeholder.com/150',
            rating: (data['rating'] ?? 0).toDouble(),
            completedServices: data['completedServices'] ?? 0,
            location: techLocation,
            services:
                List<String>.from(data['specialties'] ?? const []),
            isOnline: data['isAvailable'] ?? true,
            distanceKm: distance,
          ),
        );
      }

      technicians.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return technicians;
    } catch (_) {
      return [];
    }
  }

  /// 🧪 MOCK
  List<TechnicianLocation> _generateMockTechnicians(
      LocationData userLocation) {
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

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
        ),
        initialZoom: 13,
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
              (tech) => Marker(
                point: LatLng(
                  tech.location.latitude,
                  tech.location.longitude,
                ),
                width: 40,
                height: 40,
                child: Icon(
                  Icons.person_pin_circle,
                  color: tech.isOnline
                      ? AppColors.success
                      : AppColors.grey400,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
