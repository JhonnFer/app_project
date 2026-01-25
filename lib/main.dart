import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'injection_container.dart' as di;

// Core
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'features/auth/data/datasources/notification_service.dart';

// Session
import 'features/auth/presentation/providers/session_provider.dart';

// Screens
import 'features/auth/presentation/pages/screens/auth/login_screen.dart';
import 'features/auth/presentation/pages/screens/auth/register_screen.dart';
import 'features/auth/presentation/pages/screens/splash_screen.dart';
import 'features/auth/presentation/pages/screens/dashboard/dashboard_screen.dart';
import 'features/auth/presentation/pages/screens/dashboard/guest_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔔 Inicializar Firebase Cloud Messaging
  final notificationService = NotificationService();
  await notificationService.initialize();

  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<SessionManager>(
      create: (_) => SessionManager(),
      child: MaterialApp(
        title: 'App Técnicos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        navigatorKey: AppRouter.navigatorKey,

        initialRoute: AppRoutes.splash,

        // 👇 RUTAS SIMPLES (splash, auth, dashboards)
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.dashboard: (_) => const DashboardScreen(),
          AppRoutes.guestDashboard: (_) => const GuestDashboardScreen(),
        },

        // 👇 RUTAS COMPLEJAS / PROTEGIDAS
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
