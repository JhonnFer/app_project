import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/location.dart';

class LocationModel extends LocationData {
  LocationModel({
    required super.userId,
    required super.latitude,
    required super.longitude,
    required super.accuracy,
    required super.address,
    required super.timestamp,
  });

  factory LocationModel.fromEntity(LocationData entity) {
    return LocationModel(
      userId: entity.userId,
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracy: entity.accuracy,
      address: entity.address,
      timestamp: entity.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'address': address,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
