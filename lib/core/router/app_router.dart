import 'package:field_service/features/auth/view/login_screen.dart';
import 'package:field_service/features/auth/view/signup_screen.dart';
import 'package:field_service/features/customer/view/customer_home_screen.dart';
import 'package:field_service/features/customer/view/customer_profile_screen.dart';
import 'package:field_service/features/customer/view/request_tracking_screen.dart';
import 'package:field_service/features/customer/view/service_request_screen.dart';
import 'package:field_service/features/customer/viewmodel/customer_home_view_model.dart';
import 'package:field_service/features/customer/viewmodel/customer_profile_view_model.dart';
import 'package:field_service/features/onboarding/view/onboarding_screen.dart';
import 'package:field_service/features/splash/view/splash_screen.dart';
import 'package:field_service/features/splash/viewmodel/splash_view_model.dart';

// Admin imports
import 'package:field_service/features/admin/views/admin_customers_page.dart';
import 'package:field_service/features/admin/views/admin_dashboard_page.dart';
import 'package:field_service/features/admin/views/admin_job_monitoring_page.dart';
import 'package:field_service/features/admin/views/admin_profile_page.dart';
import 'package:field_service/features/admin/views/admin_reports_page.dart';
import 'package:field_service/features/admin/views/admin_request_details_page.dart';
import 'package:field_service/features/admin/views/admin_service_requests_page.dart';
import 'package:field_service/features/admin/views/ admin_technicians_page.dart';

// Technician imports
import 'package:field_service/features/technician/view/technician_dashboard_page.dart';
import 'package:field_service/features/technician/view/technician_task_details_page.dart';
import 'package:field_service/features/technician/view/technicion_profile_screen.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/admin/viewmodels/customer_view_model.dart';
import '../../features/admin/viewmodels/job_monitoring_view_model.dart';
import '../../features/technician/viewmodel/technician_view_model.dart';
import '../di/service_locator.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) {
        return ChangeNotifierProvider(
          create: (_) => getIt<SplashViewModel>(),
          child: const SplashScreen(),
        );
      },
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      path: '/customer',
      builder: (context, state) {
        return ChangeNotifierProvider(
          create: (_) => getIt<CustomerHomeViewModel>()..loadRecentRequests(),
          child: const CustomerHomeScreen(),
        );
      },
    ),
    GoRoute(
      path: '/customer/profile',
      builder: (context, state) {
        return ChangeNotifierProvider(
          create: (_) => CustomerProfileViewModel()..loadProfile(),
          child: const CustomerProfileScreen(),
        );
      },
    ),
    GoRoute(
      path: '/customer/service-request',
      builder: (context, state) {
        final String category = (state.extra as String?) ?? 'Electrical';
        return ServiceRequestScreen(category: category);
      },
    ),
    GoRoute(
      path: '/customer/request-tracking',
      builder: (context, state) {
        final request = (state.extra as Map<String, dynamic>?) ?? {};
        return CustomerRequestTrackingPage(request: request);
      },
    ),
    // Admin Routes
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardPage(),
    ),
    GoRoute(
      path: '/admin/requests',
      builder: (context, state) => const AdminServiceRequestsPage(),
    ),
    GoRoute(
      path: '/admin/technicians',
      builder: (context, state) {
        return ChangeNotifierProvider<TechnicianViewModel>(
          create: (_) => getIt<TechnicianViewModel>(),
          child: const AdminTechniciansPage(),
        );
      },
    ),
    GoRoute(
      path: '/admin/customers',
      builder: (context, state) {
        return ChangeNotifierProvider<CustomerViewModel>(
          create: (_) => getIt<CustomerViewModel>(),
          child: const AdminCustomersPage(),
        );
      },
    ),
    GoRoute(
      path: '/admin/jobs',

      builder: (context, state) {
        return ChangeNotifierProvider<JobMonitoringViewModel>(
          create: (_) => getIt<JobMonitoringViewModel>(),
          child: const AdminJobMonitoringPage(),
        );
      },
    ),
    GoRoute(
      path: '/admin/reports',
      builder: (context, state) => const AdminReportsPage(),
    ),
    GoRoute(
      path: '/admin/profile',
      builder: (context, state) => const AdminProfilePage(),
    ),
    GoRoute(
      path: '/admin/request-details',
      builder: (context, state) {
        final request = (state.extra as Map<String, dynamic>?) ?? {};
        return AdminRequestDetailsPage(request: request);
      },
    ),
    // Technician Routes
    GoRoute(
      path: '/technician',
      builder: (context, state) => const TechnicianDashboardPage(),
    ),
    GoRoute(
      path: '/technician/task-details/:id',
      builder: (context, state) {
        final taskId = state.pathParameters['id'] ?? '';
        return TechnicianTaskDetailsPage(taskId: taskId);
      },
    ),
    GoRoute(
      path: '/technician/profile',
      builder: (context, state) => const TechnicianProfilePage(),
    ),
  ],
);
