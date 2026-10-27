import 'package:field_service/database/local_database.dart';
import 'package:field_service/features/auth/viewmodel/auth_view_model.dart';
import 'package:field_service/features/customer/viewmodel/customer_home_view_model.dart';
import 'package:field_service/features/customer/viewmodel/customer_profile_view_model.dart';
import 'package:field_service/features/customer/viewmodel/customer_request_tracking_view_model.dart';
import 'package:field_service/features/customer/viewmodel/service_request_view_model.dart';
import 'package:field_service/features/splash/viewmodel/splash_view_model.dart';
import 'package:field_service/providers/internet_provider.dart';
import 'package:field_service/repositorys/auth_repository.dart';
import 'package:field_service/repositorys/customer_profile_repository.dart';
import 'package:field_service/repositorys/customer_request_tracking_repository.dart';
import 'package:field_service/repositorys/service_request_form_repository.dart';
import 'package:field_service/repositorys/service_request_repository.dart';
import 'package:field_service/services/api_service.dart';
import 'package:field_service/services/network_service.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Database & Services
  getIt.registerLazySingleton<LocalDatabase>(() => LocalDatabase());
  getIt.registerLazySingleton<NetworkService>(() => NetworkService());
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  getIt.registerLazySingleton<InternetProvider>(
    () => InternetProvider(getIt<NetworkService>()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      apiService: getIt<ApiService>(),
      client: Supabase.instance.client,
      internetProvider: getIt<InternetProvider>(),
      localDatabase: getIt<LocalDatabase>(),
    ),
  );
  getIt.registerLazySingleton<CustomerProfileRepository>(
    () => CustomerProfileRepository(
      apiService: getIt<ApiService>(),
      localDatabase: getIt<LocalDatabase>(),
    ),
  );
  getIt.registerLazySingleton<CustomerRequestTrackingRepository>(
    () => CustomerRequestTrackingRepository(
      apiService: getIt<ApiService>(),
      client: Supabase.instance.client,
    ),
  );
  getIt.registerLazySingleton<ServiceRequestRepository>(
    () => ServiceRequestRepository(
      localDatabase: getIt<LocalDatabase>(),
      client: Supabase.instance.client,
      apiService: getIt<ApiService>(),
    ),
  );
  getIt.registerLazySingleton<ServiceRequestFormRepository>(
    () => ServiceRequestFormRepository(
      apiService: getIt<ApiService>(),
      database: getIt<LocalDatabase>(),
      authRepository: getIt<AuthRepository>(),
      serviceRequestRepository: getIt<ServiceRequestRepository>(),
    ),
  );

  // ViewModels
  getIt.registerFactory<AuthViewModel>(
    () => AuthViewModel(getIt<AuthRepository>()),
  );
  getIt.registerFactory<SplashViewModel>(() => SplashViewModel());
  getIt.registerFactory<CustomerHomeViewModel>(() => CustomerHomeViewModel());
  getIt.registerFactory<CustomerProfileViewModel>(
    () => CustomerProfileViewModel(),
  );
  getIt.registerFactoryParam<ServiceRequestViewModel, String, void>(
    (category, _) => ServiceRequestViewModel(category: category),
  );
  getIt.registerFactoryParam<
    CustomerRequestTrackingViewModel,
    Map<String, dynamic>,
    void
  >((request, _) => CustomerRequestTrackingViewModel(request: request));
}
