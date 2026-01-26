// lib/features/auth/presentation/widgets/common/permission_button.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_permissions.dart';
import '../../../../core/utils/permission_extensions.dart';
import '../../domain/entities/user_entity.dart';

/// Botón que solo se muestra si el usuario tiene el permiso requerido
class PermissionButton extends StatelessWidget {
  final UserEntity? user;
  final Permission requiredPermission;
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  final bool isElevated;
  final Color? backgroundColor;

  const PermissionButton({
    Key? key,
    required this.user,
    required this.requiredPermission,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isElevated = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // No mostrar si no hay usuario
    if (user == null) {
      return const SizedBox.shrink();
    }

    // No mostrar si no tiene permiso
    if (!user!.hasPermission(requiredPermission)) {
      return const SizedBox.shrink();
    }

    // Mostrar botón con el permiso
    if (isElevated) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(label),
    );
  }
}

/// Botón que requiere múltiples permisos (todos)
class MultiPermissionButton extends StatelessWidget {
  final UserEntity? user;
  final List<Permission> requiredPermissions;
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  final bool isElevated;
  final Color? backgroundColor;

  const MultiPermissionButton({
    Key? key,
    required this.user,
    required this.requiredPermissions,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isElevated = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    if (!user!.hasAllPermissions(requiredPermissions)) {
      return const SizedBox.shrink();
    }

    if (isElevated) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(label),
    );
  }
}

/// Botón para roles específicos
class RoleButton extends StatelessWidget {
  final UserEntity? user;
  final List<UserRole> allowedRoles;
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  final bool isElevated;
  final Color? backgroundColor;

  const RoleButton({
    Key? key,
    required this.user,
    required this.allowedRoles,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isElevated = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    if (!allowedRoles.contains(user!.role)) {
      return const SizedBox.shrink();
    }

    if (isElevated) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(label),
    );
  }
}
