// lib/core/routes/app_router.dart
import 'package:flutter/material.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../constants/app_permissions.dart';

/// Router centralizado con protección de permisos
/// EJEMPLO DE USO: Solo para mostrar cómo implementarlo
class AppRouter {
  static final _navigatorKey = GlobalKey<NavigatorState>();

  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// Verifica si es posible acceder a una ruta
  /// Retorna true si puede acceder, false si no
  static bool canAccessRoute({
    required String routeName,
    required UserEntity? currentUser,
  }) {
    switch (routeName) {
      // Rutas públicas
      case AppRoutes.login:
      case AppRoutes.register:
      case AppRoutes.splash:
        return true;

      // Rutas que requieren autenticación
      case AppRoutes.dashboard:
        return currentUser != null && !currentUser.isGuest;

      case AppRoutes.clientDashboard:
        return currentUser != null && currentUser.isClient;

      case AppRoutes.technicianDashboard:
        return currentUser != null && currentUser.isTechnician;

      case AppRoutes.guestDashboard:
        return currentUser != null && currentUser.isGuest;

      // Rutas que requieren permisos específicos
      case AppRoutes.createService:
        return currentUser != null &&
            PermissionManager.userHasPermission(
              currentUser,
              Permission.createService,
            );

      case AppRoutes.profile:
        return currentUser != null &&
            PermissionManager.userHasPermission(
              currentUser,
              Permission.editProfile,
            );

      case AppRoutes.chat:
        return currentUser != null &&
            PermissionManager.userHasPermission(
              currentUser,
              Permission.chatWithTechnician,
            );

      case AppRoutes.location:
        return currentUser != null &&
            PermissionManager.userHasPermission(
              currentUser,
              Permission.viewNearbyServices,
            );

      default:
        return currentUser != null;
    }
  }

  /// Obtiene los permisos requeridos para una ruta
  static List<Permission> getRequiredPermissions(String routeName) {
    switch (routeName) {
      case AppRoutes.createService:
        return [Permission.createService];

      case AppRoutes.chat:
        return [Permission.chatWithTechnician];

      case AppRoutes.location:
        return [Permission.viewNearbyServices];

      case AppRoutes.profile:
        return [Permission.editProfile];

      default:
        return [];
    }
  }

  /// Navega a una ruta si el usuario tiene permiso
  static Future<dynamic>? safeNavigate({
    required String routeName,
    required UserEntity? currentUser,
    Object? arguments,
  }) {
    if (!canAccessRoute(
      routeName: routeName,
      currentUser: currentUser,
    )) {
      ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text(
            'No tienes permiso para acceder a esta sección',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    return _navigatorKey.currentState?.pushNamed(
      routeName,
      arguments: arguments,
    );
  }
}

/// Clase con las rutas disponibles
abstract class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String clientDashboard = '/client-dashboard';
  static const String technicianDashboard = '/technician-dashboard';
  static const String guestDashboard = '/guest-dashboard';
  static const String profile = '/profile';
  static const String chat = '/chat';
  static const String serviceDetail = '/service-detail';
  static const String createService = '/create-service';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String location = '/location';
  
}
