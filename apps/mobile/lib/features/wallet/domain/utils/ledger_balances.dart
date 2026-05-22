import 'package:eco_wallet/features/wallet/domain/entities/coin_ledger_entry.dart';

class LedgerBalances {
  const LedgerBalances({
    required this.pendingTotal,
    required this.availableTotal,
  });

  final int pendingTotal;
  final int availableTotal;

  int get total => pendingTotal + availableTotal;
}

LedgerBalances balancesFromLedgerEntries(List<CoinLedgerEntry> entries) {
  var pending = 0;
  var available = 0;

  for (final entry in entries) {
    switch (entry.type) {
      case CoinEntryType.pending:
        pending += entry.amount;
      case CoinEntryType.available:
        available += entry.amount;
      case CoinEntryType.spent:
        available -= entry.amount;
    }
  }

  return LedgerBalances(
    pendingTotal: pending < 0 ? 0 : pending,
    availableTotal: available < 0 ? 0 : available,
  );
}
