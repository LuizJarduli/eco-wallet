import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eco_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eco_wallet/features/auth/presentation/pages/login_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(
      const AuthSignInRequested(email: '', password: ''),
    );
  });

  setUp(() {
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthUnauthenticated());
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => authBloc.add(any())).thenReturn(null);
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const LoginPage(),
      ),
    );
  }

  testWidgets('login button shows loading indicator while submitting', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'maria.demo@ecowallet.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'demo123456');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    verifyNever(() => authBloc.add(any()));
  });

  testWidgets('dispatches sign-in event when form is valid', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.enterText(find.byType(TextFormField).at(0), 'student@unifacens.edu.br');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret12');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    verify(
      () => authBloc.add(
        const AuthSignInRequested(
          email: 'student@unifacens.edu.br',
          password: 'secret12',
        ),
      ),
    ).called(1);
  });

  testWidgets('login button is enabled when not loading', (tester) async {
    await tester.pumpWidget(buildSubject());

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    expect(button.onPressed, isNotNull);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
