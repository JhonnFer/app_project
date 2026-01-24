// lib/features/auth/domain/usecases/register_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase implements UseCase<UserEntity, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) async {
    return await repository.signUp(
      params.email,
      params.password,
      params.name,
      params.role,
      params.phone,
    );
  }
}

class RegisterParams {
  final String email;
  final String password;
  final String name;
  final String role;
  final String? phone;

  RegisterParams({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.phone,
  });
}