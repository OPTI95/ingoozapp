import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/promo/data/datasources/promo_remote_data_source.dart';
import '../../features/promo/data/repositories/promo_repository_impl.dart';
import '../../features/promo/domain/repositories/promo_repository.dart';
import '../../features/promo/presentation/bloc/promo_bloc.dart';
import '../../features/billing/data/datasources/billing_remote_data_source.dart';
import '../../features/billing/data/repositories/billing_repository_impl.dart';
import '../../features/billing/domain/repositories/billing_repository.dart';
import '../../features/billing/presentation/bloc/top_up_bloc.dart';
import '../../features/guide/data/datasources/guide_remote_data_source.dart';
import '../../features/guide/data/repositories/guide_repository_impl.dart';
import '../../features/guide/domain/repositories/guide_repository.dart';
import '../../features/guide/presentation/bloc/guide_bloc.dart';
import '../../features/vehicles/data/datasources/vehicle_remote_data_source.dart';
import '../../features/vehicles/data/repositories/vehicle_repository_impl.dart';
import '../../features/vehicles/domain/repositories/vehicle_repository.dart';
import '../../features/vehicles/presentation/bloc/vehicle_form_bloc.dart';
import '../../features/vehicles/presentation/bloc/vehicles_bloc.dart';
import '../../features/waybills/data/datasources/waybill_remote_data_source.dart';
import '../../features/waybills/data/repositories/waybill_repository_impl.dart';
import '../../features/waybills/domain/repositories/waybill_repository.dart';
import '../../features/waybills/presentation/bloc/waybill_issue_bloc.dart';
import '../../features/waybills/presentation/bloc/waybills_bloc.dart';
import '../network/dio_client.dart';
import '../storage/token_storage.dart';

/// Global service locator. Call [configureDependencies] once in `main`.
final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  // --- core ---
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  sl.registerLazySingleton<TokenStorage>(() => TokenStorage(sl()));
  sl.registerLazySingleton<Dio>(() => DioClient.create(sl()));

  // --- auth feature ---
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remote: sl(), tokenStorage: sl()),
  );
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));

  // --- profile feature ---
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl()),
  );
  sl.registerFactory<ProfileBloc>(() => ProfileBloc(sl()));

  // --- vehicles feature ---
  sl.registerLazySingleton<VehicleRemoteDataSource>(
    () => VehicleRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<VehicleRepository>(
    () => VehicleRepositoryImpl(sl()),
  );
  sl.registerFactory<VehiclesBloc>(() => VehiclesBloc(sl()));
  sl.registerFactory<VehicleFormBloc>(() => VehicleFormBloc(sl()));

  // --- waybills feature ---
  sl.registerLazySingleton<WaybillRemoteDataSource>(
    () => WaybillRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<WaybillRepository>(
    () => WaybillRepositoryImpl(sl()),
  );
  sl.registerFactory<WaybillsBloc>(() => WaybillsBloc(sl()));
  sl.registerFactory<WaybillIssueBloc>(
    () => WaybillIssueBloc(
      waybillRepository: sl(),
      vehicleRepository: sl(),
    ),
  );

  // --- billing feature ---
  sl.registerLazySingleton<BillingRemoteDataSource>(
    () => BillingRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<BillingRepository>(
    () => BillingRepositoryImpl(sl()),
  );
  sl.registerFactory<TopUpBloc>(() => TopUpBloc(sl()));

  // --- promo feature ---
  sl.registerLazySingleton<PromoRemoteDataSource>(
    () => PromoRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<PromoRepository>(
    () => PromoRepositoryImpl(sl()),
  );
  sl.registerFactory<PromoBloc>(
    () => PromoBloc(promoRepository: sl(), profileRepository: sl()),
  );

  // --- guide feature ---
  sl.registerLazySingleton<GuideRemoteDataSource>(
    () => GuideRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<GuideRepository>(
    () => GuideRepositoryImpl(sl()),
  );
  sl.registerFactory<GuideBloc>(() => GuideBloc(sl()));
}
