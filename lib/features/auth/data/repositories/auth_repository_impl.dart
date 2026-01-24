// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_service.dart';
import '../datasources/local_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, UserEntity>> signIn(
    String email,
    String password,
  ) async {
    try {
      final credential = await remoteDataSource.signIn(email, password);
      final userData = await remoteDataSource.getUserData(credential.user!.uid);

      if (userData == null) {
        return Left(ServerFailure('No se encontraron datos del usuario'));
      }

      final userEntity = UserModel.fromJson(userData);
      // Guardar sesión localmente
      await localDataSource.saveSession(userEntity);
      return Right(userEntity);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp(
    String email,
    String password,
    String name,
    String role,
    String? phone,
  ) async {
    try {
      final credential = await remoteDataSource.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
      );
      final userData = await remoteDataSource.getUserData(credential.user!.uid);

      if (userData == null) {
        return Left(ServerFailure('Error al crear el usuario'));
      }

      final userEntity = UserModel.fromJson(userData);
      // Guardar sesión localmente
      await localDataSource.saveSession(userEntity);
      return Right(userEntity);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      // Limpiar sesión local
      await localDataSource.clearSession();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.signOut();
      // Limpiar sesión local
      await localDataSource.clearSession();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await remoteDataSource.resetPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final firebaseUser = remoteDataSource.getCurrentUser();

      if (firebaseUser == null) {
        return Left(NoUserFailure());
      }

      final userData = await remoteDataSource.getUserData(firebaseUser.uid);

      if (userData == null) {
        return Left(NoUserFailure());
      }

      return Right(UserModel.fromJson(userData));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return remoteDataSource.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        await localDataSource.clearSession();
        return null;
      }

      final userData = await remoteDataSource.getUserData(firebaseUser.uid);
      if (userData == null) return null;

      final userEntity = UserModel.fromJson(userData);
      // Actualizar sesión local cuando el estado cambia
      await localDataSource.saveSession(userEntity);
      return userEntity;
    });
  }

  @override
  Future<Either<Failure, UserEntity?>> checkSession() async {
    try {
      final userEntity = await localDataSource.getSession();
      if (userEntity != null) {
        return Right(userEntity);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUserServices(
      String uid) async {
    try {
      final services = await remoteDataSource.getUserServices(uid);
      return Right(services);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
