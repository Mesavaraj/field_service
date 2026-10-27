import 'package:field_service/core/router/app_router.dart';
import 'package:field_service/features/auth/viewmodel/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/di/service_locator.dart';

class FsmApp extends StatelessWidget {
  const FsmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<AuthViewModel>(),
      child: MaterialApp.router(
        title: 'FixMate',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.primaryDark,
            elevation: 0,
            centerTitle: false,
          ),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
