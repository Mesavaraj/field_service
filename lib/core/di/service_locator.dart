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
import 'package:field_service/repositorys/admin_profile_repository.dart';
import 'package:field_service/repositorys/technician_local_repository.dart';
import 'package:field_service/repositorys/technician_repository.dart';
import 'package:field_service/repositorys/technician_task_details_repository.dart';

import 'package:field_service/features/admin/viewmodels/admin_profile_view_model.dart';
import 'package:field_service/features/technician/viewmodel/technician_view_model.dart';
import 'package:field_service/features/technician/viewmodel/technician_dashboard_viewmodel.dart';
import 'package:field_service/features/technician/viewmodel/technician_task_details_viewmodel.dart';

import 'package:field_service/services/api_service.dart';
import 'package:field_service/services/network_service.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/admin/viewmodels/customer_view_model.dart';
import '../../features/admin/viewmodels/job_monitoring_view_model.dart';
import '../../repositorys/customer_repository.dart';
import '../../repositorys/job_monitoring_repository.dart';

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

  getIt.registerLazySingleton<AdminProfileRepository>(
    () => AdminProfileRepository(Supabase.instance.client),
  );
  getIt.registerLazySingleton<TechnicianLocalRepository>(
    () => TechnicianLocalRepository(),
  );

  getIt.registerLazySingleton<TechnicianRepository>(
    () => TechnicianRepository(
      client: Supabase.instance.client,
      localRepository: getIt<TechnicianLocalRepository>(),
    ),
  );
  getIt.registerLazySingleton<TechnicianTaskDetailsRepository>(
    () => TechnicianTaskDetailsRepository(
      client: Supabase.instance.client,
      local: getIt<TechnicianLocalRepository>(),
    ),
  );
  getIt.registerLazySingleton<CustomerRepository>(
    () => CustomerRepository(Supabase.instance.client),
  );
  getIt.registerLazySingleton<JobMonitoringRepository>(
    () => JobMonitoringRepository(Supabase.instance.client),
  );

  // ViewModels
  getIt.registerFactory<CustomerViewModel>(
    () => CustomerViewModel(getIt<CustomerRepository>()),
  );
  getIt.registerFactory<JobMonitoringViewModel>(
    () => JobMonitoringViewModel(getIt<JobMonitoringRepository>()),
  );
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

  getIt.registerFactory<AdminProfileViewModel>(
    () => AdminProfileViewModel(getIt<AdminProfileRepository>()),
  );
  getIt.registerFactory<TechnicianViewModel>(
    () => TechnicianViewModel(getIt<TechnicianRepository>()),
  );
  getIt.registerFactory<TechnicianDashboardViewModel>(
    () => TechnicianDashboardViewModel(getIt<TechnicianRepository>()),
  );
  getIt.registerFactoryParam<TechnicianTaskDetailsViewModel, String, void>(
    (taskId, _) => TechnicianTaskDetailsViewModel(
      repository: getIt<TechnicianTaskDetailsRepository>(),
      taskId: taskId,
    ),
  );
}
