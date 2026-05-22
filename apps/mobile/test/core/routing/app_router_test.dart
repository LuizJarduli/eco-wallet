import 'package:flutter_test/flutter_test.dart';

import 'package:eco_wallet/core/constants/app_routes.dart';
import 'package:eco_wallet/core/routing/app_router.dart';
import 'package:eco_wallet/features/auth/domain/entities/auth_user.dart';
import 'package:eco_wallet/features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  const user = AuthUser(id: 'id', email: 'a@b.com');

  test('redirects authenticated users to home', () {
    expect(
      AppRouter.redirectFor(const AuthAuthenticated(user)),
      AppRoutes.home,
    );
  });

  test('redirects unauthenticated users to login', () {
    expect(
      AppRouter.redirectFor(const AuthUnauthenticated()),
      AppRoutes.login,
    );
  });
}
