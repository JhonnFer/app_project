// lib/features/auth/presentation/pages/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/usecases/check_session_usecase.dart';

final sl = GetIt.instance;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Esperar 1 segundo para mostrar la splash
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Verificar si hay sesión guardada
      final result = await sl<CheckSessionUseCase>()(NoParams());

      result.fold(
        // Si hay error, ir a login
        (failure) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
        // Si hay usuario, ir al dashboard
        (user) {
          if (user != null) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          } else if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
      );
    } catch (e) {
      // Error, ir a login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(size: 80),
            const SizedBox(height: 24),
            Text(
              'App Técnicos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
