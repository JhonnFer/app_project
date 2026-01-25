import 'dart:math' as math;

class LocationData {
  final String userId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final String address;
  final DateTime timestamp;

  LocationData({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.address,
    required this.timestamp,
  });

  String get formattedCoordinates => '$latitude, $longitude';

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
    return earthRadiusKm * c * 1000;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}
