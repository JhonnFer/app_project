import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() => _instance;

  LocationService._internal();

  Future<bool> requestLocationPermission() async {
    final status = await Geolocator.requestPermission();
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 🔥 SOLO retorna Position (infraestructura pura)
  Future<Position> getCurrentPosition() async {
    final isEnabled = await isLocationServiceEnabled();
    if (!isEnabled) {
      throw Exception('El servicio de ubicación no está habilitado');
    }

    final hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      throw Exception('Permiso de ubicación denegado');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );
  }

  // Utilidad (NO dominio)
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
    return earthRadiusKm * c * 1000;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}
