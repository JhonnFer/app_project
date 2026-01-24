// lib/core/utils/permission_extensions.dart
import '../constants/app_permissions.dart';
import '../../features/auth/domain/entities/user_entity.dart';

/// Extensión para hacer más legible el código de permisos
extension PermissionExtension on UserEntity {
  /// Verifica si el usuario tiene un permiso específico
  bool hasPermission(Permission permission) {
    return PermissionManager.userHasPermission(this, permission);
  }

  /// Verifica si tiene TODOS los permisos
  bool hasAllPermissions(List<Permission> permissions) {
    return PermissionManager.userHasAllPermissions(this, permissions);
  }

  /// Verifica si tiene AL MENOS UNO de los permisos
  bool hasAnyPermission(List<Permission> permissions) {
    return PermissionManager.userHasAnyPermission(this, permissions);
  }

  /// Getters de conveniencia para permisos comunes
  bool get canCreateService => hasPermission(Permission.createService);
  bool get canAcceptService => hasPermission(Permission.acceptService);
  bool get canCompleteService => hasPermission(Permission.completeService);
  bool get canViewClientProfile => hasPermission(Permission.viewClientProfile);
  bool get canEditProfile => hasPermission(Permission.editProfile);
  bool get canChatWithTechnician =>
      hasPermission(Permission.chatWithTechnician);
  bool get canViewNearbyServices =>
      hasPermission(Permission.viewNearbyServices);
  bool get canReceivePayments => hasPermission(Permission.receivePayments);
}
