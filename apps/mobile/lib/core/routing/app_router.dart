import 'package:flutter/material.dart';

import 'package:eco_wallet/core/constants/app_routes.dart';
import 'package:eco_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eco_wallet/features/auth/presentation/pages/login_page.dart';
import 'package:eco_wallet/features/auth/presentation/pages/register_page.dart';
import 'package:eco_wallet/features/home/presentation/pages/home_page.dart';

/// Auth-aware route table and redirect helper.
class AppRouter {
  const AppRouter._();

  static String redirectFor(AuthState state) {
    if (state is AuthAuthenticated) {
      return AppRoutes.home;
    }
    if (state is AuthUnauthenticated || state is AuthFailure) {
      return AppRoutes.login;
    }
    return AppRoutes.login;
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoginPage(),
        );
      case AppRoutes.register:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const RegisterPage(),
        );
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const HomePage(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoginPage(),
        );
    }
  }
}
