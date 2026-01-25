import '../entities/location.dart';
import '../repositories/location_repository.dart';

/// Caso de uso: Guardar ubicación del usuario
/// 
/// Se usa tanto para:
/// - Ubicación manual
/// - Ubicación obtenida desde mapa/GPS
class SaveLocationUseCase {
  final LocationRepository repository;

  SaveLocationUseCase(this.repository);

  Future<void> call({
    required String userId,
    required double latitude,
    required double longitude,
    required String sector,
    double accuracy = 0,
  }) async {
    final location = LocationData(
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      address: sector,
      timestamp: DateTime.now(),
    );

    await repository.saveLocation(location);
  }
}
