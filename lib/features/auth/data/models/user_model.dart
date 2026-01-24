// lib/features/auth/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.name,
    required super.role,
    super.phone,
    super.profileImage,
    super.rating,
    super.serviceCount,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: _roleFromString(json['role'] as String),
      phone: json['phone'] as String?,
      profileImage: json['profileImage'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      serviceCount: json['serviceCount'] as int?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': _roleToString(role),
      'phone': phone,
      'profileImage': profileImage,
      'rating': rating,
      'serviceCount': serviceCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      email: entity.email,
      name: entity.name,
      role: entity.role,
      phone: entity.phone,
      profileImage: entity.profileImage,
      rating: entity.rating,
      serviceCount: entity.serviceCount,
      createdAt: entity.createdAt,
    );
  }

  // Convertir UserRole a String para Firebase
  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.client:
        return 'client';
      case UserRole.technician:
        return 'technician';
      case UserRole.guest:
        return 'guest';
    }
  }

  // Convertir String a UserRole desde Firebase
  static UserRole _roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'technician':
        return UserRole.technician;
      case 'client':
        return UserRole.client;
      case 'guest':
        return UserRole.guest;
      default:
        return UserRole.client;
    }
  }
}