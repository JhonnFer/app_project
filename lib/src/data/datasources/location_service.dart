import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/location.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  Future<bool> requestLocationPermission() async {
    final status = await Geolocator.requestPermission();
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<LocationData> getCurrentLocation() async {
    // Verificar si el servicio de ubicación está habilitado
    final isEnabled = await isLocationServiceEnabled();
    if (!isEnabled) {
      throw Exception('El servicio de ubicación no está habilitado');
    }

    // Verificar permisos
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      throw Exception('Permiso de ubicación denegado');
    }

    // Obtener posición actual
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );

    // Obtener dirección (geocodificación inversa aproximada)
    final address = await _getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      address: address,
      timestamp: DateTime.now(),
    );
  }

  Stream<LocationData> getLocationStream({
    Duration updateInterval = const Duration(seconds: 5),
  }) async* {
    // Verificar si el servicio de ubicación está habilitado
    final isEnabled = await isLocationServiceEnabled();
    if (!isEnabled) {
      throw Exception('El servicio de ubicación no está habilitado');
    }

    // Obtener stream de posición
    final positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualizar cada 10 metros
      ),
    );

    await for (final position in positionStream) {
      final address = await _getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      yield LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        address: address,
        timestamp: DateTime.now(),
      );
    }
  }

  // Geocodificación inversa aproximada (sin API externa)
  Future<String> _getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Aquí podrías integrar una API de geocodificación como Nominatim
      // Por ahora retornamos las coordenadas
      return 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}';
    } catch (e) {
      return 'Ubicación: $latitude, $longitude';
    }
  }

  // Distancia entre dos puntos
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadiusKm * c * 1000; // Retorna en metros
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}
