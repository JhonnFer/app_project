// lib/core/routes/route_guard.dart
import 'package:flutter/material.dart';
import '../constants/app_permissions.dart';
import '../../features/auth/domain/entities/user_entity.dart';

/// Guard para proteger rutas basado en permisos
class RouteGuard {
  /// Verifica si el usuario puede acceder a la ruta
  static bool canAccess({
    required UserEntity? user,
    required List<Permission> requiredPermissions,
    bool requireAuth = true,
  }) {
    // Si no hay usuario y se requiere autenticación
    if (user == null && requireAuth) {
      return false;
    }

    // Si no hay usuario pero no se requiere autenticación
    if (user == null) {
      return true;
    }

    // Verificar si tiene todos los permisos requeridos
    return requiredPermissions.isEmpty ||
        requiredPermissions.every((permission) =>
            PermissionManager.userHasPermission(user, permission));
  }

  /// Verifica si el usuario tiene AL MENOS UNO de los permisos
  static bool canAccessAny({
    required UserEntity? user,
    required List<Permission> requiredPermissions,
    bool requireAuth = true,
  }) {
    if (user == null && requireAuth) {
      return false;
    }

    if (user == null) {
      return true;
    }

    return requiredPermissions.isEmpty ||
        requiredPermissions.any((permission) =>
            PermissionManager.userHasPermission(user, permission));
  }

  /// Verifica si el usuario es un rol específico
  static bool hasRole({
    required UserEntity? user,
    required UserRole role,
  }) {
    return user?.role == role;
  }

  /// Verifica si el usuario tiene UNO de los roles especificados
  static bool hasAnyRole({
    required UserEntity? user,
    required List<UserRole> roles,
  }) {
    return user != null && roles.contains(user.role);
  }
}

/// Widget guard que muestra contenido solo si el usuario tiene permisos
class PermissionGuard extends StatelessWidget {
  final UserEntity? user;
  final List<Permission> requiredPermissions;
  final Widget child;
  final Widget? fallback;
  final bool requireAll;

  const PermissionGuard({
    Key? key,
    required this.user,
    required this.requiredPermissions,
    required this.child,
    this.fallback,
    this.requireAll = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasAccess = requireAll
        ? RouteGuard.canAccess(
            user: user,
            requiredPermissions: requiredPermissions,
            requireAuth: false,
          )
        : RouteGuard.canAccessAny(
            user: user,
            requiredPermissions: requiredPermissions,
            requireAuth: false,
          );

    if (hasAccess) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget guard para mostrar contenido solo para roles específicos
class RoleGuard extends StatelessWidget {
  final UserEntity? user;
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    Key? key,
    required this.user,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasAccess = RouteGuard.hasAnyRole(
      user: user,
      roles: allowedRoles,
    );

    if (hasAccess) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
