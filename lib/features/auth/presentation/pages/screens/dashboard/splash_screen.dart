// lib/features/auth/presentation/pages/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../domain/usecases/check_session_usecase.dart';

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
  // Mostrar splash
  await Future.delayed(const Duration(seconds: 1));

  try {
    final result = await sl<CheckSessionUseCase>()(NoParams());

    result.fold(
      // Error → Login
      (failure) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      },

      // Usuario válido → Dashboard correcto
      (user) {
        if (!mounted) return;

        if (user == null) {
          Navigator.of(context).pushReplacementNamed('/login');
          return;
        }

        // 👇 navegación normal de la app
        Navigator.of(context).pushReplacementNamed('/dashboard');
      },
    );
  } catch (_) {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
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
