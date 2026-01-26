// lib/features/auth/presentation/widgets/common/role_restricted_widget.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/permission_extensions.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/constants/app_permissions.dart';

/// Widget que muestra contenido solo para un rol específico
class RoleRestrictedWidget extends StatelessWidget {
  final UserEntity? user;
  final UserRole allowedRole;
  final Widget child;
  final Widget? restrictedMessage;

  const RoleRestrictedWidget({
    Key? key,
    required this.user,
    required this.allowedRole,
    required this.child,
    this.restrictedMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (user == null || user!.role != allowedRole) {
      return restrictedMessage ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: AppColors.warning.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: AppColors.warning,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Función no disponible',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Esta función está disponible solo para ${allowedRole.name}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
    }

    return child;
  }
}

/// Widget que muestra contenido si el usuario tiene un permiso
class PermissionRestrictedWidget extends StatelessWidget {
  final UserEntity? user;
  final Permission requiredPermission;
  final Widget child;
  final Widget? restrictedMessage;

  const PermissionRestrictedWidget({
    Key? key,
    required this.user,
    required this.requiredPermission,
    required this.child,
    this.restrictedMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (user == null || !user!.hasPermission(requiredPermission)) {
      return restrictedMessage ?? const SizedBox.shrink();
    }

    return child;
  }
}

/// Muestra un aviso disimulado cuando no hay permiso
class PermissionDependentWidget extends StatelessWidget {
  final UserEntity? user;
  final Permission requiredPermission;
  final Widget child;
  final bool showMessageWhenRestricted;

  const PermissionDependentWidget({
    Key? key,
    required this.user,
    required this.requiredPermission,
    required this.child,
    this.showMessageWhenRestricted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasPermission =
        user != null && user!.hasPermission(requiredPermission);

    if (!hasPermission && showMessageWhenRestricted) {
      return Opacity(
        opacity: 0.5,
        child: Stack(
          children: [
            child,
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No disponible',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return hasPermission ? child : const SizedBox.shrink();
  }
}
