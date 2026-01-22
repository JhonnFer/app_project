enum UserRole {
  client,
  technician,
  guest,
}

class User {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String phone;
  final String? profileImage;
  final double? rating;
  final int? serviceCount;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.phone,
    this.profileImage,
    this.rating,
    this.serviceCount,
    required this.createdAt,
  });

  // Para técnico
  factory User.technician({
    required String id,
    required String email,
    required String fullName,
    required String phone,
    String? profileImage,
    double rating = 0.0,
    int serviceCount = 0,
    required DateTime createdAt,
  }) {
    return User(
      id: id,
      email: email,
      fullName: fullName,
      role: UserRole.technician,
      phone: phone,
      profileImage: profileImage,
      rating: rating,
      serviceCount: serviceCount,
      createdAt: createdAt,
    );
  }

  // Para cliente
  factory User.client({
    required String id,
    required String email,
    required String fullName,
    required String phone,
    String? profileImage,
    required DateTime createdAt,
  }) {
    return User(
      id: id,
      email: email,
      fullName: fullName,
      role: UserRole.client,
      phone: phone,
      profileImage: profileImage,
      createdAt: createdAt,
    );
  }

  // Para invitado
  factory User.guest() {
    return User(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: '',
      fullName: 'Usuario Invitado',
      role: UserRole.guest,
      phone: '',
      createdAt: DateTime.now(),
    );
  }
}
