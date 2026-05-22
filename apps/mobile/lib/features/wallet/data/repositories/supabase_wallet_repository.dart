import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:eco_wallet/core/errors/wallet_exception.dart';
import 'package:eco_wallet/features/wallet/data/models/coin_ledger_entry_model.dart';
import 'package:eco_wallet/features/wallet/data/models/coin_wallet_model.dart';
import 'package:eco_wallet/features/wallet/domain/entities/coin_ledger_entry.dart';
import 'package:eco_wallet/features/wallet/domain/entities/coin_wallet.dart';
import 'package:eco_wallet/features/wallet/domain/repositories/wallet_repository.dart';

class SupabaseWalletRepository implements WalletRepository {
  SupabaseWalletRepository({sb.SupabaseClient? client})
    : _client = client ?? sb.Supabase.instance.client;

  final sb.SupabaseClient _client;
  sb.RealtimeChannel? _walletChannel;
  CoinWalletChanged? _walletChanged;

  @override
  Future<CoinWallet> fetchWallet({required String userId}) async {
    try {
      final row =
          await _client
              .from('coin_wallets')
              .select('user_id,pending_balance,available_balance,updated_at')
              .eq('user_id', userId)
              .maybeSingle();

      if (row == null) {
        return CoinWallet(
          userId: userId,
          pendingBalance: 0,
          availableBalance: 0,
          updatedAt: DateTime.now().toUtc(),
        );
      }

      return CoinWalletModel.fromJson(row).toEntity();
    } on sb.PostgrestException catch (error) {
      throw WalletException(_messageFromPostgrest(error));
    }
  }

  @override
  Future<List<CoinLedgerEntry>> fetchLedger({required String userId}) async {
    try {
      final rows = await _client
          .from('coin_ledger')
          .select('id,amount,type,reference_id,created_at')
          .eq('wallet_user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return (rows as List<dynamic>)
          .map(
            (row) =>
                CoinLedgerEntryModel.fromJson(row as Map<String, dynamic>)
                    .toEntity(),
          )
          .toList(growable: false);
    } on sb.PostgrestException catch (error) {
      throw WalletException(_messageFromPostgrest(error));
    }
  }

  @override
  void subscribeToWallet({
    required String userId,
    required CoinWalletChanged onChanged,
  }) {
    unsubscribeFromWallet();
    _walletChanged = onChanged;
    _walletChannel =
        _client
            .channel('coin_wallets:$userId')
            .onPostgresChanges(
              event: sb.PostgresChangeEvent.all,
              schema: 'public',
              table: 'coin_wallets',
              filter: sb.PostgresChangeFilter(
                type: sb.PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (payload) {
                final record = payload.newRecord;
                if (record.isEmpty) {
                  return;
                }
                _walletChanged?.call(CoinWalletModel.fromJson(record).toEntity());
              },
            )
            .subscribe();
  }

  @override
  void unsubscribeFromWallet() {
    final channel = _walletChannel;
    if (channel != null) {
      _client.removeChannel(channel);
    }
    _walletChannel = null;
    _walletChanged = null;
  }

  String _messageFromPostgrest(sb.PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('permission') || message.contains('policy')) {
      return 'Sem permissão para acessar a carteira. Entre novamente.';
    }
    return 'Não foi possível carregar a carteira. Tente novamente.';
  }
}
