// lib/core/constants/app_permissions.dart
import '../../features/auth/domain/entities/user_entity.dart';

/// Define los permisos disponibles en la aplicación
enum Permission {
  // Permisos de Cliente
  createService,
  viewServices,
  rateService,
  chatWithTechnician,
  cancelService,

  // Permisos de Técnico
  acceptService,
  completeService,
  viewClientProfile,
  editProfile,
  manageServices,
  receivePayments,
  viewNearbyServices,

  // Permisos de Invitado
  viewPublicInfo,
  viewTechnicians,
  searchServices,

  // Permisos Administrativos
  manageUsers,
  viewAnalytics,
  blockUsers,
}

/// Mapea cada rol a sus permisos específicos
class PermissionManager {
  static const Map<UserRole, List<Permission>> rolePermissions = {
    UserRole.client: [
      Permission.createService,
      Permission.viewServices,
      Permission.rateService,
      Permission.chatWithTechnician,
      Permission.cancelService,
      Permission.viewPublicInfo,
      Permission.viewTechnicians,
    ],
    UserRole.technician: [
      Permission.acceptService,
      Permission.completeService,
      Permission.viewClientProfile,
      Permission.editProfile,
      Permission.manageServices,
      Permission.receivePayments,
      Permission.viewNearbyServices,
      Permission.viewPublicInfo,
      Permission.chatWithTechnician,
    ],
    UserRole.guest: [
      Permission.viewPublicInfo,
      Permission.viewTechnicians,
      Permission.searchServices,
    ],
  };

  /// Verifica si un rol tiene un permiso específico
  static bool hasPermission(UserRole role, Permission permission) {
    return rolePermissions[role]?.contains(permission) ?? false;
  }

  /// Verifica si un usuario tiene un permiso
  static bool userHasPermission(UserEntity user, Permission permission) {
    return hasPermission(user.role, permission);
  }

  /// Obtiene todos los permisos de un rol
  static List<Permission> getPermissionsForRole(UserRole role) {
    return rolePermissions[role] ?? [];
  }

  /// Verifica si el usuario tiene TODOS los permisos especificados
  static bool userHasAllPermissions(
    UserEntity user,
    List<Permission> permissions,
  ) {
    return permissions
        .every((permission) => userHasPermission(user, permission));
  }

  /// Verifica si el usuario tiene AL MENOS UNO de los permisos
  static bool userHasAnyPermission(
    UserEntity user,
    List<Permission> permissions,
  ) {
    return permissions.any((permission) => userHasPermission(user, permission));
  }
}
