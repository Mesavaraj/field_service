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
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
  ],
);
