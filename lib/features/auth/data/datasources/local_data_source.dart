// lib/features/auth/data/datasources/local_data_source.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_storage.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthLocalDataSource {
  /// Guardar sesión del usuario localmente
  Future<void> saveSession(UserEntity user);

  /// Obtener sesión guardada del usuario
  Future<UserEntity?> getSession();

  /// Limpiar sesión del usuario
  Future<void> clearSession();

  /// Verificar si existe sesión activa
  Future<bool> hasActiveSession();

  /// Obtener UID guardado
  Future<String?> getSavedUid();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences _prefs;

  AuthLocalDataSourceImpl({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  Future<void> saveSession(UserEntity user) async {
    await Future.wait([
      _prefs.setString(AppStorageKeys.USER_UID, user.uid),
      _prefs.setString(AppStorageKeys.USER_EMAIL, user.email),
      _prefs.setString(AppStorageKeys.USER_NAME, user.name),
      _prefs.setString(AppStorageKeys.USER_ROLE, user.role.name),
      _prefs.setString(AppStorageKeys.USER_PHONE, user.phone ?? ''),
      _prefs.setString(
          AppStorageKeys.USER_PROFILE_IMAGE, user.profileImage ?? ''),
      _prefs.setDouble(AppStorageKeys.USER_RATING, user.rating ?? 0.0),
      _prefs.setInt(AppStorageKeys.USER_SERVICE_COUNT, user.serviceCount ?? 0),
      _prefs.setString(AppStorageKeys.USER_CREATED_AT,
          user.createdAt?.toIso8601String() ?? ''),
      _prefs.setBool(AppStorageKeys.IS_LOGGED_IN, true),
    ]);
  }

  @override
  Future<UserEntity?> getSession() async {
    final isLoggedIn = _prefs.getBool(AppStorageKeys.IS_LOGGED_IN) ?? false;

    if (!isLoggedIn) {
      return null;
    }

    try {
      final uid = _prefs.getString(AppStorageKeys.USER_UID);
      final email = _prefs.getString(AppStorageKeys.USER_EMAIL);
      final name = _prefs.getString(AppStorageKeys.USER_NAME);
      final roleStr = _prefs.getString(AppStorageKeys.USER_ROLE);
      final phone = _prefs.getString(AppStorageKeys.USER_PHONE);
      final profileImage = _prefs.getString(AppStorageKeys.USER_PROFILE_IMAGE);
      final rating = _prefs.getDouble(AppStorageKeys.USER_RATING);
      final serviceCount = _prefs.getInt(AppStorageKeys.USER_SERVICE_COUNT);
      final createdAtStr = _prefs.getString(AppStorageKeys.USER_CREATED_AT);

      if (uid == null || email == null || name == null || roleStr == null) {
        return null;
      }

      final role = UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.guest,
      );

      return UserEntity(
        uid: uid,
        email: email,
        name: name,
        role: role,
        phone: phone?.isEmpty ?? true ? null : phone,
        profileImage: profileImage?.isEmpty ?? true ? null : profileImage,
        rating: rating,
        serviceCount: serviceCount,
        createdAt: createdAtStr?.isNotEmpty ?? false
            ? DateTime.parse(createdAtStr!)
            : null,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    await Future.wait([
      _prefs.remove(AppStorageKeys.USER_UID),
      _prefs.remove(AppStorageKeys.USER_EMAIL),
      _prefs.remove(AppStorageKeys.USER_NAME),
      _prefs.remove(AppStorageKeys.USER_ROLE),
      _prefs.remove(AppStorageKeys.USER_PHONE),
      _prefs.remove(AppStorageKeys.USER_PROFILE_IMAGE),
      _prefs.remove(AppStorageKeys.USER_RATING),
      _prefs.remove(AppStorageKeys.USER_SERVICE_COUNT),
      _prefs.remove(AppStorageKeys.USER_CREATED_AT),
      _prefs.remove(AppStorageKeys.IS_LOGGED_IN),
    ]);
  }

  @override
  Future<bool> hasActiveSession() async {
    return _prefs.getBool(AppStorageKeys.IS_LOGGED_IN) ?? false;
  }

  @override
  Future<String?> getSavedUid() async {
    return _prefs.getString(AppStorageKeys.USER_UID);
  }
}
