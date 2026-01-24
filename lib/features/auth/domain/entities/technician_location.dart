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

  // Calcular distancia desde una ubicación
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_toRadians(lat1)) *
            Math.cos(_toRadians(lat2)) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);

    final c = 2 * Math.asin(Math.sqrt(a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * (3.141592653589793 / 180.0);
}

class Math {
  static double sin(double x) => throw UnimplementedError();
  static double cos(double x) => throw UnimplementedError();
  static double sqrt(double x) => throw UnimplementedError();
  static double asin(double x) => throw UnimplementedError();
}
