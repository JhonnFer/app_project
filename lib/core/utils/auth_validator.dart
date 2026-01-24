// lib/core/utils/auth_validator.dart
import '../constants/app_permissions.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../error/failures.dart';

/// Validador de operaciones basado en permisos
class AuthValidator {
  /// Valida que el usuario tenga un permiso específico
  /// Lanza una excepción si no lo tiene
  static void requirePermission(
    UserEntity user,
    Permission permission, {
    String? customMessage,
  }) {
    if (!PermissionManager.userHasPermission(user, permission)) {
      throw UnauthorizedFailure(
        customMessage ??
            'No tienes permiso para realizar esta acción. '
                'Se requiere: ${permission.name}',
      );
    }
  }

  /// Valida que el usuario tenga TODOS los permisos
  static void requireAllPermissions(
    UserEntity user,
    List<Permission> permissions, {
    String? customMessage,
  }) {
    final missingPermissions = permissions
        .where((p) => !PermissionManager.userHasPermission(user, p))
        .toList();

    if (missingPermissions.isNotEmpty) {
      throw UnauthorizedFailure(
        customMessage ??
            'Faltan permisos: ${missingPermissions.map((p) => p.name).join(', ')}',
      );
    }
  }

  /// Valida que el usuario tenga AL MENOS UNO de los permisos
  static void requireAnyPermission(
    UserEntity user,
    List<Permission> permissions, {
    String? customMessage,
  }) {
    final hasAny = permissions.any(
      (p) => PermissionManager.userHasPermission(user, p),
    );

    if (!hasAny) {
      throw UnauthorizedFailure(
        customMessage ??
            'Necesitas uno de estos permisos: ${permissions.map((p) => p.name).join(', ')}',
      );
    }
  }

  /// Valida que el usuario sea un rol específico
  static void requireRole(
    UserEntity user,
    UserRole role, {
    String? customMessage,
  }) {
    if (user.role != role) {
      throw UnauthorizedFailure(
        customMessage ?? 'Esta acción solo está disponible para ${role.name}',
      );
    }
  }

  /// Valida que el usuario sea uno de los roles especificados
  static void requireAnyRole(
    UserEntity user,
    List<UserRole> roles, {
    String? customMessage,
  }) {
    if (!roles.contains(user.role)) {
      throw UnauthorizedFailure(
        customMessage ??
            'Esta acción requiere uno de estos roles: ${roles.map((r) => r.name).join(', ')}',
      );
    }
  }

  /// Valida que el usuario no sea invitado
  static void requireAuthenticated(
    UserEntity? user, {
    String? customMessage,
  }) {
    if (user == null || user.isGuest) {
      throw UnauthorizedFailure(
        customMessage ?? 'Debes estar autenticado para realizar esta acción',
      );
    }
  }
}

/// Extensión para hacer validaciones más fáciles
extension AuthValidationExtension on UserEntity {
  /// Valida que tenga un permiso, lanza excepción si no lo tiene
  void validate(Permission permission) {
    AuthValidator.requirePermission(this, permission);
  }

  /// Valida que tenga todos los permisos
  void validateAll(List<Permission> permissions) {
    AuthValidator.requireAllPermissions(this, permissions);
  }

  /// Valida que tenga al menos uno de los permisos
  void validateAny(List<Permission> permissions) {
    AuthValidator.requireAnyPermission(this, permissions);
  }

  /// Valida que sea un rol específico
  void validateRole(UserRole role) {
    AuthValidator.requireRole(this, role);
  }
}

/// Clase para definir excepciones de autorización
class UnauthorizedFailure implements Failure {
  @override
  final String message;

  UnauthorizedFailure(this.message);

  @override
  String toString() => 'UnauthorizedFailure: $message';

  @override
  List<Object> get props => [message];

  @override
  bool? get stringify => true;
}
