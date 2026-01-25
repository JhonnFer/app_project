import 'package:flutter/material.dart';
import '../../../../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../providers/session_provider.dart';
import 'technician_notifications_tab.dart';

/// 🔔 Screen de notificaciones - Acceso según rol
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  UserEntity? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final session = SessionManager();
    UserEntity? user = session.currentUser;

    if (user == null) {
      user = await session.checkSession();
    }

    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notificaciones'),
          elevation: 0,
        ),
        
      );
    }

    // 🔐 Verificar rol: Solo técnicos pueden ver notificaciones
    if (_currentUser?.role != UserRole.technician) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notificaciones'),
          elevation: 0,
        ),
        
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: AppColors.grey300,
              ),
              const SizedBox(height: 16),
              const Text(
                'No disponible',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Esta función solo está disponible para técnicos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Es técnico: mostrar notificaciones
    return const TechnicianNotificationsTab();
  }
}
