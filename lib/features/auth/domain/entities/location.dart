import 'dart:math' as math;

class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String address;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.address,
    required this.timestamp,
  });

  // Método para obtener coordenadas formateadas
  String get formattedCoordinates => '$latitude, $longitude';

  // Distancia aproximada entre dos puntos en metros (Haversine)
  double distanceTo(LocationData other) {
    const double earthRadiusKm = 6371.0;
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);

    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadiusKm * c * 1000; // Retorna en metros
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}
