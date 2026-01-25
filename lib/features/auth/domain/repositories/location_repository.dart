import '../entities/location.dart';

abstract class LocationRepository {
  /// Guarda la ubicación del cliente (manual o automática)
  Future<void> saveLocation(LocationData location);

  /// Obtiene la última ubicación guardada
  Future<LocationData?> getLastLocation(String userId);
}
