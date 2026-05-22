import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eco_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eco_wallet/features/auth/presentation/pages/register_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(
      const AuthSignUpRequested(email: '', password: ''),
    );
  });

  setUp(() {
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthUnauthenticated());
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => authBloc.add(any())).thenReturn(null);
  });

  testWidgets('register button shows loading indicator while submitting', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const RegisterPage(),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'novo@ecowallet.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'demo123456');
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('dispatches sign-up event when form is valid', (tester) async {
    when(() => authBloc.state).thenReturn(const AuthUnauthenticated());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const RegisterPage(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'student@unifacens.edu.br');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret12');
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();

    verify(
      () => authBloc.add(
        const AuthSignUpRequested(
          email: 'student@unifacens.edu.br',
          password: 'secret12',
        ),
      ),
    ).called(1);
  });
}
