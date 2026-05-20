import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eco_wallet/app.dart';
import 'package:eco_wallet/core/constants/env.dart';
import 'package:eco_wallet/core/theme/app_colors.dart';
import 'package:eco_wallet/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:eco_wallet/features/disposal/data/repositories/supabase_disposal_repository.dart';
import 'package:eco_wallet/features/wallet/data/repositories/supabase_wallet_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(
    EcoWalletApp(
      authRepository: SupabaseAuthRepository(),
      disposalRepository: SupabaseDisposalRepository(),
      walletRepository: SupabaseWalletRepository(),
    ),
  );
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
                  'Defina SUPABASE_URL e SUPABASE_ANON_KEY com --dart-define '
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
