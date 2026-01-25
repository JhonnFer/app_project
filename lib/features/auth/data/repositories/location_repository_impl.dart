import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';
import '../models/location_model.dart';

class LocationRepositoryImpl implements LocationRepository {
  @override
  Future<void> saveLocation(LocationData location) async {
    final model = LocationModel.fromEntity(location);

    await FirebaseFirestore.instance
        .collection('user_locations')
        .doc(model.userId)
        .set(model.toJson());

    print('✅ Ubicación guardada en Firebase: ${model.toJson()}');
  }

  @override
  Future<LocationData?> getLastLocation(String userId) async {
    return null;
  }
}
