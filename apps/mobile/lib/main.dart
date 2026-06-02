import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eco_wallet/app.dart';
import 'package:eco_wallet/core/bloc/app_bloc_observer.dart';
import 'package:eco_wallet/core/constants/env.dart';
import 'package:eco_wallet/core/notifications/device_token_registrar.dart';
import 'package:eco_wallet/core/notifications/device_token_repository.dart';
import 'package:eco_wallet/core/notifications/firebase_push_token_service.dart';
import 'package:eco_wallet/core/notifications/noop_push_token_service.dart';
import 'package:eco_wallet/core/notifications/push_token_service.dart';
import 'package:eco_wallet/core/theme/app_colors.dart';
import 'package:eco_wallet/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:eco_wallet/features/disposal/data/repositories/supabase_disposal_repository.dart';
import 'package:eco_wallet/features/rewards/data/repositories/supabase_rewards_repository.dart';
import 'package:eco_wallet/features/wallet/data/repositories/supabase_wallet_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();

  if (!Env.isConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseClientKey,
  );

  final pushTokenService = await _createPushTokenService();

  runApp(
    EcoWalletApp(
      authRepository: SupabaseAuthRepository(),
      deviceTokenRegistrar: DeviceTokenRegistrar(
        deviceTokenRepository: DeviceTokenRepository(),
        pushTokenService: pushTokenService,
      ),
      disposalRepository: SupabaseDisposalRepository(),
      rewardsRepository: SupabaseRewardsRepository(),
      walletRepository: SupabaseWalletRepository(),
    ),
  );
}

Future<PushTokenService> _createPushTokenService() async {
  if (!Env.enablePushNotifications) {
    return NoOpPushTokenService();
  }

  await Firebase.initializeApp();
  return FirebasePushTokenService();
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuração necessária',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Defina SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY com --dart-define '
                  'antes de executar o app. Consulte apps/mobile/README.md.',
                  style: TextStyle(color: AppColors.stone),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
