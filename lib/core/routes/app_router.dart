// lib/core/routes/app_router.dart
import 'package:flutter/material.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../constants/app_permissions.dart';

// Screens
import '../../features/auth/presentation/pages/screens/location/location_screen.dart';
import '../../features/auth/presentation/pages/screens/dashboard/dashboard_screen.dart';
import '../../features/auth/presentation/pages/screens/dashboard/guest_dashboard_screen.dart';
import '../../features/auth/presentation/pages/screens/dashboard/service_request_form_screen.dart';
import '../../features/auth/presentation/pages/screens/dashboard/notifications_screen.dart';
import '../../features/auth/presentation/pages/screens/auth/login_screen.dart';
import '../../features/auth/presentation/pages/screens/auth/register_screen.dart';
import '../../features/auth/presentation/pages/screens/dashboard/splash_screen.dart';

/// Router centralizado con protección de permisos
/// EJEMPLO DE USO: Solo para mostrar cómo implementarlo
/// Router centralizado con control de permisos
/// RESPONSABILIDAD ÚNICA: navegación
class AppRouter {
  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  // ============================================================
  // VALIDACIÓN DE ACCESO POR RUTA
  // ============================================================
  static bool canAccessRoute({
    required String routeName,
    required UserEntity? currentUser,
  }) {
    switch (routeName) {
      // Rutas públicas
      case AppRoutes.splash:
      case AppRoutes.login:
      case AppRoutes.register:
        return true;

      // Dashboards
      case AppRoutes.dashboard:
        return currentUser != null && !currentUser.isGuest;

      case AppRoutes.guestDashboard:
        return currentUser != null && currentUser.isGuest;

      case AppRoutes.clientDashboard:
        return currentUser != null && currentUser.isClient;

      case AppRoutes.technicianDashboard:
        return currentUser != null && currentUser.isTechnician;

      // Rutas con permisos
      case AppRoutes.location:
        return currentUser != null &&
            PermissionManager.userHasPermission(
              currentUser,
              Permission.viewNearbyServices,
            );

      case AppRoutes.chat:
        return currentUser != null &&
            PermissionManager.userHasPermission(
              currentUser,
              Permission.chatWithTechnician,
            );

      case AppRoutes.profile:
        return currentUser != null &&
            PermissionManager.userHasPermission(
              currentUser,
              Permission.editProfile,
            );

      case AppRoutes.notifications:
        return currentUser != null && currentUser.isTechnician;

      case AppRoutes.createService:
      case AppRoutes.serviceRequest:
        return currentUser != null &&
            PermissionManager.userHasPermission(
              currentUser,
              Permission.createService,
            );

      default:
        return false;
    }
  }

  // ============================================================
  // PERMISOS REQUERIDOS POR RUTA
  // ============================================================
  static List<Permission> getRequiredPermissions(String routeName) {
    switch (routeName) {
      case AppRoutes.location:
        return [Permission.viewNearbyServices];

      case AppRoutes.chat:
        return [Permission.chatWithTechnician];

      case AppRoutes.profile:
        return [Permission.editProfile];

      case AppRoutes.createService:
      case AppRoutes.serviceRequest:
        return [Permission.createService];

      default:
        return [];
    }
  }

  // ============================================================
  // NAVEGACIÓN SEGURA
  // ============================================================
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
          content: Text('No tienes permiso para acceder a esta sección'),
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

  // ============================================================
  // GENERADOR CENTRAL DE RUTAS (OBLIGATORIO)
  // ============================================================
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );

      case AppRoutes.register:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RegisterScreen(),
        );

      case AppRoutes.dashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DashboardScreen(),
        );

      case AppRoutes.guestDashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const GuestDashboardScreen(),
        );

      case AppRoutes.location:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LocationScreen(),
        );
      case AppRoutes.serviceRequest:
        final user = settings.arguments as UserEntity?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ServiceRequestFormScreen(user: user),
        );

      case AppRoutes.notifications:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const NotificationsScreen(),
        );

      
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Ruta no encontrada'),
            ),
          ),
        );
    }
  }
}

/// ============================================================
/// RUTAS DISPONIBLES EN LA APP
/// ============================================================
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
  static const String location = '/location';

  static const String createService = '/create-service';
  static const String serviceRequest = '/service-request';
  static const String serviceDetail = '/service-detail';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String testPriceFlow = '/test-price-flow';
}
