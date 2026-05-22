import 'package:supabase_flutter/supabase_flutter.dart' as sb hide AuthUser;

import 'package:eco_wallet/core/errors/auth_exception.dart' as app_auth;
import 'package:eco_wallet/features/auth/domain/entities/auth_user.dart';
import 'package:eco_wallet/features/auth/domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({sb.GoTrueClient? auth})
    : _auth = auth ?? sb.Supabase.instance.client.auth;

  final sb.GoTrueClient _auth;

  @override
  AuthUser? get currentUser {
    final session = _auth.currentSession;
    final user = session?.user;
    if (user == null) {
      return null;
    }
    return _mapUser(user);
  }

  @override
  Future<AuthUser?> restoreSession() async => currentUser;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const app_auth.AuthException(
          'Não foi possível entrar. Tente novamente.',
        );
      }
      return _mapUser(user);
    } on sb.AuthException catch (error) {
      throw app_auth.AuthException(_messageFromSupabase(error));
    }
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const app_auth.AuthException(
          'Não foi possível criar a conta. Tente novamente.',
        );
      }
      return _mapUser(user);
    } on sb.AuthException catch (error) {
      throw app_auth.AuthException(_messageFromSupabase(error));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  AuthUser _mapUser(sb.User user) {
    return AuthUser(id: user.id, email: user.email);
  }

  String _messageFromSupabase(sb.AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'E-mail ou senha inválidos.';
    }
    if (message.contains('user already registered')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (message.contains('password')) {
      return 'A senha não atende aos requisitos mínimos.';
    }
    return 'Não foi possível concluir a operação. Tente novamente.';
  }
}
