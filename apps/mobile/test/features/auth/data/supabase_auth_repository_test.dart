import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb hide AuthUser;

import 'package:eco_wallet/core/errors/auth_exception.dart' as app_auth;
import 'package:eco_wallet/features/auth/data/repositories/supabase_auth_repository.dart';

class MockGoTrueClient extends Mock implements sb.GoTrueClient {}

class MockAuthResponse extends Mock implements sb.AuthResponse {}

class MockSession extends Mock implements sb.Session {}

class MockUser extends Mock implements sb.User {}

void main() {
  late MockGoTrueClient auth;
  late SupabaseAuthRepository repository;

  setUp(() {
    auth = MockGoTrueClient();
    repository = SupabaseAuthRepository(auth: auth);
    when(() => auth.currentSession).thenReturn(null);
  });

  test('currentUser returns null when session is missing', () {
    expect(repository.currentUser, isNull);
  });

  test('currentUser maps session user', () {
    final user = MockUser();
    final session = MockSession();
    when(() => user.id).thenReturn('id-1');
    when(() => user.email).thenReturn('a@b.com');
    when(() => session.user).thenReturn(user);
    when(() => auth.currentSession).thenReturn(session);

    final result = repository.currentUser;

    expect(result?.id, 'id-1');
    expect(result?.email, 'a@b.com');
  });

  test('signIn maps invalid credentials to pt-BR message', () async {
    when(
      () => auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const sb.AuthException('Invalid login credentials'));

    expect(
      () => repository.signIn(email: 'a@b.com', password: 'x'),
      throwsA(
        isA<app_auth.AuthException>().having(
          (error) => error.message,
          'message',
          'E-mail ou senha inválidos.',
        ),
      ),
    );
  });

  test('signIn returns mapped user on success', () async {
    final response = MockAuthResponse();
    final user = MockUser();
    when(() => user.id).thenReturn('id-2');
    when(() => user.email).thenReturn('student@unifacens.edu.br');
    when(() => response.user).thenReturn(user);
    when(
      () => auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => response);

    final result = await repository.signIn(
      email: 'student@unifacens.edu.br',
      password: 'secret12',
    );

    expect(result.id, 'id-2');
  });

  test('signUp maps user already registered message', () async {
    when(
      () => auth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const sb.AuthException('User already registered'));

    expect(
      () => repository.signUp(email: 'a@b.com', password: 'secret12'),
      throwsA(
        isA<app_auth.AuthException>().having(
          (error) => error.message,
          'message',
          'Este e-mail já está cadastrado.',
        ),
      ),
    );
  });

  test('signOut delegates to Supabase auth client', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});

    await repository.signOut();

    verify(() => auth.signOut()).called(1);
  });
}
