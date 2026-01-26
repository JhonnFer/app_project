// lib/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===== Auth =====
import 'features/auth/data/datasources/auth_service.dart';
import 'features/auth/data/datasources/local_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/check_session_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/get_user_services_usecase.dart';

// ===== Location =====
import 'features/auth/data/repositories/location_repository_impl.dart';
import 'features/auth/domain/repositories/location_repository.dart';
import 'features/auth/domain/usecases/save_location_usecase.dart';

//oferta de servicios
import 'features/auth/data/datasources/price_negotiation_remote_datasource.dart';
import 'features/auth/data/repositories/price_negotiation_repository_impl.dart';
import 'features/auth/domain/repositories/price_negotiation_repository.dart';
import 'features/auth/domain/usecases/get_pending_negotiations_usecase.dart';
import 'features/auth/domain/usecases/respond_to_negotiation_usecase.dart';
import 'features/auth/data/datasources/price_negotiation_remote_datasource_impl.dart';


final sl = GetIt.instance;

Future<void> init() async {
  // ===== Auth =====
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => CheckSessionUseCase(repository: sl()));
  sl.registerLazySingleton(() => LogoutUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetUserServicesUseCase(repository: sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      auth: sl(),
      firestore: sl(),
    ),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(prefs: sl()),
  );

  // ===== Location =====
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(),
  );

  sl.registerLazySingleton(
    () => SaveLocationUseCase(sl()),
  );

  // ===== External =====
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);


  // PRICE NEGOTIATION
  // ===============================

  // Datasource
  sl.registerLazySingleton<PriceNegotiationRemoteDatasource>(
    () => PriceNegotiationRemoteDatasourceImpl(
      firestore: sl(),
    ),
  );
  // Repository
  sl.registerLazySingleton<PriceNegotiationRepository>(
    () => PriceNegotiationRepositoryImpl(sl()),
  );

  // UseCases
  sl.registerLazySingleton(
    () => GetPendingNegotiationsUseCase(sl()),
  );

  sl.registerLazySingleton(
    () => RespondToNegotiationUseCase(sl()),
  );
}
