import 'dart:math' as math;
import 'location.dart';

class TechnicianLocation {
  final String id;
  final String name;
  final String profileImage;
  final double rating;
  final int completedServices;
  final LocationData location;
  final List<String> services;
  final bool isOnline;
  final double distanceKm;

  TechnicianLocation({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.rating,
    required this.completedServices,
    required this.location,
    required this.services,
    required this.isOnline,
    required this.distanceKm,
  });

  // Calcular distancia desde una ubicación usando la fórmula de Haversine
  static double calculateDistance(
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
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}
