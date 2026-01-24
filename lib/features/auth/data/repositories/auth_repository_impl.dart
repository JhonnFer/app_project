// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_service.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

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

      return Right(UserModel.fromJson(userData));
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

      return Right(UserModel.fromJson(userData));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
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
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final firebaseUser = remoteDataSource.getCurrentUser();
      if (firebaseUser == null) return const Right(null);

      final userData = await remoteDataSource.getUserData(firebaseUser.uid);
      if (userData == null) return const Right(null);

      return Right(UserModel.fromJson(userData));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return remoteDataSource.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      final userData = await remoteDataSource.getUserData(firebaseUser.uid);
      if (userData == null) return null;

      return UserModel.fromJson(userData);
    });
  }
}
