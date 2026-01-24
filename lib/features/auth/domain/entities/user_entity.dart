// lib/features/auth/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

enum UserRole {
  client,
  technician,
  guest,
}

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? phone;
  final String? profileImage;
  final double? rating;
  final int? serviceCount;
  final DateTime? createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.profileImage,
    this.rating,
    this.serviceCount,
    this.createdAt,
  });

  // Getters de conveniencia
  bool get isTechnician => role == UserRole.technician;
  bool get isClient => role == UserRole.client;
  bool get isGuest => role == UserRole.guest;

  // Factory para técnico
  factory UserEntity.technician({
    required String uid,
    required String email,
    required String name,
    required String phone,
    String? profileImage,
    double rating = 0.0,
    int serviceCount = 0,
    DateTime? createdAt,
  }) {
    return UserEntity(
      uid: uid,
      email: email,
      name: name,
      role: UserRole.technician,
      phone: phone,
      profileImage: profileImage,
      rating: rating,
      serviceCount: serviceCount,
      createdAt: createdAt,
    );
  }

  // Factory para cliente
  factory UserEntity.client({
    required String uid,
    required String email,
    required String name,
    required String phone,
    String? profileImage,
    DateTime? createdAt,
  }) {
    return UserEntity(
      uid: uid,
      email: email,
      name: name,
      role: UserRole.client,
      phone: phone,
      profileImage: profileImage,
      createdAt: createdAt,
    );
  }

  // Factory para invitado
  factory UserEntity.guest() {
    return UserEntity(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: '',
      name: 'Usuario Invitado',
      role: UserRole.guest,
      createdAt: DateTime.now(),
    );
  }

  // CopyWith para inmutabilidad
  UserEntity copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
    String? phone,
    String? profileImage,
    double? rating,
    int? serviceCount,
    DateTime? createdAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      rating: rating ?? this.rating,
      serviceCount: serviceCount ?? this.serviceCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        name,
        role,
        phone,
        profileImage,
        rating,
        serviceCount,
        createdAt,
      ];
}