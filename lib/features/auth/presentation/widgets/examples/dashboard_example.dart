// lib/features/auth/presentation/widgets/examples/dashboard_example.dart
// ESTE ARCHIVO ES UN EJEMPLO DE CÓMO USAR EL SISTEMA DE PERMISOS EN TU DASHBOARD
// Cópialo y adaptalo a tu dashboard_screen.dart

import 'package:flutter/material.dart';
import '../../../../../core/constants/app_permissions.dart';
import '../../../../../core/utils/permission_extensions.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../common/permission_button.dart';
import '../common/role_restricted_widget.dart';

class DashboardPermissionExample extends StatelessWidget {
  final UserEntity currentUser;

  const DashboardPermissionExample({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // === EJEMPLO 1: Mostrar sección solo para clientes ===
          RoleRestrictedWidget(
            user: currentUser,
            allowedRole: UserRole.client,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi Panel de Cliente',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    // Botón que solo aparece si tiene permiso
                    PermissionButton(
                      user: currentUser,
                      requiredPermission: Permission.createService,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Crear nuevo servicio'),
                          ),
                        );
                      },
                      label: 'Solicitar Servicio',
                      icon: Icons.add,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // === EJEMPLO 2: Mostrar sección solo para técnicos ===
          RoleRestrictedWidget(
            user: currentUser,
            allowedRole: UserRole.technician,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi Panel de Técnico',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    // Mostrar botones solo si el técnico tiene los permisos
                    if (currentUser.canAcceptService)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Ver Servicios Disponibles'),
                        ),
                      ),
                    if (currentUser.canCompleteService)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.done_all),
                          label: const Text('Mis Servicios Activos'),
                        ),
                      ),
                    if (currentUser.canReceivePayments)
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.attach_money),
                        label: const Text('Pagos'),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // === EJEMPLO 3: Usar PermissionRestrictedWidget para contenido ===
          PermissionRestrictedWidget(
            user: currentUser,
            requiredPermission: Permission.chatWithTechnician,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mis Chats',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Este usuario puede chatear',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // === EJEMPLO 4: Mostrar información del usuario y sus permisos ===
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mi Información',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nombre: ${currentUser.name}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Correo: ${currentUser.email}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Rol: ${currentUser.role.name.toUpperCase()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Permisos disponibles:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  // Mostrar todos los permisos del usuario
                  ...PermissionManager.getPermissionsForRole(currentUser.role)
                      .map((permission) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '✓ ${permission.name}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === EJEMPLOS DE USO EN CONDICIONES ===
class PermissionCheckExamples {
  // Verificar un permiso específico
  static void example1(UserEntity user) {
    if (user.hasPermission(Permission.createService)) {
      // Mostrar opción para crear servicio
    }
  }

  // Verificar múltiples permisos
  static void example2(UserEntity user) {
    if (user.hasAllPermissions([
      Permission.createService,
      Permission.chatWithTechnician,
    ])) {
      // Usuario tiene TODOS estos permisos
    }
  }

  // Verificar al menos uno de varios permisos
  static void example3(UserEntity user) {
    if (user.hasAnyPermission([
      Permission.acceptService,
      Permission.completeService,
    ])) {
      // Usuario tiene AL MENOS UNO de estos permisos
    }
  }

  // Verificar usando getters rápidos
  static void example4(UserEntity user) {
    if (user.canCreateService) {
      // Usuario puede crear servicios
    }

    if (user.canAcceptService) {
      // Usuario puede aceptar servicios
    }

    if (user.isTechnician) {
      // Usuario es técnico
    }
  }

  // Verificar rol específico
  static void example5(UserEntity user) {
    if (user.role == UserRole.technician) {
      // Es un técnico
    }
  }
}
