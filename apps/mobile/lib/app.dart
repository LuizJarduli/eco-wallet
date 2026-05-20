import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_wallet/core/notifications/device_token_registrar.dart';
import 'package:eco_wallet/core/routing/app_router.dart';
import 'package:eco_wallet/core/theme/app_theme.dart';
import 'package:eco_wallet/features/auth/domain/repositories/auth_repository.dart';
import 'package:eco_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eco_wallet/features/auth/presentation/pages/auth_flow_page.dart';
import 'package:eco_wallet/features/disposal/domain/repositories/disposal_repository.dart';
import 'package:eco_wallet/features/home/presentation/pages/home_page.dart';
import 'package:eco_wallet/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:eco_wallet/features/wallet/presentation/bloc/wallet_bloc.dart';

class EcoWalletApp extends StatelessWidget {
  const EcoWalletApp({
    required this.authRepository,
    required this.deviceTokenRegistrar,
    required this.disposalRepository,
    required this.walletRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final DeviceTokenRegistrar deviceTokenRegistrar;
  final DisposalRepository disposalRepository;
  final WalletRepository walletRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<DeviceTokenRegistrar>.value(
          value: deviceTokenRegistrar,
        ),
        RepositoryProvider<DisposalRepository>.value(
          value: disposalRepository,
        ),
        RepositoryProvider<WalletRepository>.value(
          value: walletRepository,
        ),
      ],
      child: BlocProvider(
        create:
            (_) =>
                AuthBloc(authRepository: authRepository)
                  ..add(const AuthCheckRequested()),
        child: MaterialApp(
          title: 'UniFacens EcoWallet',
          theme: AppTheme.light,
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthAuthenticated && previous is! AuthAuthenticated,
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          unawaited(
            context.read<DeviceTokenRegistrar>().registerForUser(state.user.id),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial || state is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is AuthAuthenticated) {
            return BlocProvider(
              create:
                  (context) => WalletBloc(
                    walletRepository: context.read<WalletRepository>(),
                    disposalRepository: context.read<DisposalRepository>(),
                  )..add(WalletStarted(state.user.id)),
              child: const HomePage(),
            );
          }
          return const AuthFlowPage();
        },
      ),
    );
  }
}
