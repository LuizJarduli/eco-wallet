import 'package:eco_wallet/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  AuthUser? get currentUser;

  Future<AuthUser?> restoreSession();

  Future<AuthUser> signIn({
    required String email,
    required String password,
  });

  Future<AuthUser> signUp({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
