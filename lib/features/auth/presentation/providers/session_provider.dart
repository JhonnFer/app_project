// lib/features/auth/presentation/providers/session_provider.dart
import 'package:get_it/get_it.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/check_session_usecase.dart';

final sl = GetIt.instance;

/// Clase simple para manejar la sesión sin dependencias de Riverpod
/// Puede usarse con Provider simple o StreamProvider si se necesita
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() {
    return _instance;
  }

  SessionManager._internal();

  UserEntity? _currentUser;

  UserEntity? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  /// Cargar sesión guardada desde local storage
  Future<UserEntity?> checkSession() async {
    try {
      final result = await sl<CheckSessionUseCase>()(NoParams());
      result.fold(
        (failure) => _currentUser = null,
        (user) => _currentUser = user,
      );
      return _currentUser;
    } catch (e) {
      _currentUser = null;
      return null;
    }
  }

  /// Establecer usuario actual
  void setCurrentUser(UserEntity? user) {
    _currentUser = user;
  }

  /// Limpiar sesión
  void clearSession() {
    _currentUser = null;
  }
}
