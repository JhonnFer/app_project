import 'package:flutter/material.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/constants/app_strings.dart';
import 'src/core/routes/app_routes.dart';
import 'src/core/routes/app_navigator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppNavigator.generateRoute,
    );
  }
}
