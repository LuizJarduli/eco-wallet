import 'package:eco_wallet/features/wallet/domain/entities/coin_ledger_entry.dart';
import 'package:eco_wallet/features/wallet/domain/entities/coin_wallet.dart';

typedef CoinWalletChanged = void Function(CoinWallet wallet);

abstract class WalletRepository {
  Future<CoinWallet> fetchWallet({required String userId});

  Future<List<CoinLedgerEntry>> fetchLedger({required String userId});

  void subscribeToWallet({
    required String userId,
    required CoinWalletChanged onChanged,
  });

  void unsubscribeFromWallet();
}
