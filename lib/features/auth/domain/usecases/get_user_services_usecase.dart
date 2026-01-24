// lib/features/auth/domain/usecases/get_user_services_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class GetUserServicesUseCase
    implements UseCase<Map<String, dynamic>, GetUserServicesParams> {
  final AuthRepository repository;

  GetUserServicesUseCase({required this.repository});

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
      GetUserServicesParams params) async {
    return await repository.getUserServices(params.uid);
  }
}

class GetUserServicesParams {
  final String uid;

  GetUserServicesParams({required this.uid});
}
