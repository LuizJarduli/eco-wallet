import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eco_wallet/core/errors/auth_exception.dart';
import 'package:eco_wallet/features/auth/domain/entities/auth_user.dart';
import 'package:eco_wallet/features/auth/domain/repositories/auth_repository.dart';
import 'package:eco_wallet/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;

  const testUser = AuthUser(id: 'user-1', email: 'student@unifacens.edu.br');

  setUp(() {
    authRepository = MockAuthRepository();
    when(() => authRepository.currentUser).thenReturn(null);
    when(() => authRepository.restoreSession()).thenAnswer((_) async => null);
    when(() => authRepository.signOut()).thenAnswer((_) async {});
  });

  AuthBloc buildBloc() => AuthBloc(authRepository: authRepository);

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits failure when sign-in returns invalid credentials',
      build: buildBloc,
      act:
          (bloc) => bloc.add(
            const AuthSignInRequested(
              email: 'student@unifacens.edu.br',
              password: 'wrong',
            ),
          ),
      setUp: () {
        when(
          () => authRepository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthException('E-mail ou senha inválidos.'));
      },
      expect: () => [const AuthFailure('E-mail ou senha inválidos.')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits success and authenticated user on valid login',
      build: buildBloc,
      act:
          (bloc) => bloc.add(
            const AuthSignInRequested(
              email: 'student@unifacens.edu.br',
              password: 'secret12',
            ),
          ),
      setUp: () {
        when(
          () => authRepository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => testUser);
      },
      expect: () => [const AuthAuthenticated(testUser)],
      verify: (_) {
        verify(
          () => authRepository.signIn(
            email: 'student@unifacens.edu.br',
            password: 'secret12',
          ),
        ).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits authenticated when session exists on cold start',
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      setUp: () {
        when(() => authRepository.currentUser).thenReturn(testUser);
      },
      expect: () => [const AuthBootstrapping(), const AuthAuthenticated(testUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'restores session from repository when currentUser is null',
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      setUp: () {
        when(() => authRepository.restoreSession()).thenAnswer((_) async => testUser);
      },
      expect: () => [const AuthBootstrapping(), const AuthAuthenticated(testUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits failure when sign-up fails',
      build: buildBloc,
      act:
          (bloc) => bloc.add(
            const AuthSignUpRequested(
              email: 'student@unifacens.edu.br',
              password: 'short',
            ),
          ),
      setUp: () {
        when(
          () => authRepository.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthException('Este e-mail já está cadastrado.'));
      },
      expect: () => [const AuthFailure('Este e-mail já está cadastrado.')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits unauthenticated when session check finds no user',
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [const AuthBootstrapping(), const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits authenticated on successful sign-up',
      build: buildBloc,
      act:
          (bloc) => bloc.add(
            const AuthSignUpRequested(
              email: 'student@unifacens.edu.br',
              password: 'secret12',
            ),
          ),
      setUp: () {
        when(
          () => authRepository.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => testUser);
      },
      expect: () => [const AuthAuthenticated(testUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits unauthenticated after sign-out',
      build: buildBloc,
      seed: () => const AuthAuthenticated(testUser),
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect:
          () => [const AuthLoading(), const AuthUnauthenticated()],
    );
  });
}
