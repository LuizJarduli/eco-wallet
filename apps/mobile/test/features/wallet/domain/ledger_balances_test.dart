import 'package:flutter_test/flutter_test.dart';

import 'package:eco_wallet/features/wallet/domain/entities/coin_ledger_entry.dart';
import 'package:eco_wallet/features/wallet/domain/utils/ledger_balances.dart';

void main() {
  final createdAt = DateTime.utc(2026, 5, 18);

  test('maps ledger entries to pending and available totals', () {
    final balances = balancesFromLedgerEntries([
      CoinLedgerEntry(
        id: '1',
        amount: 15,
        type: CoinEntryType.pending,
        createdAt: createdAt,
      ),
      CoinLedgerEntry(
        id: '2',
        amount: 10,
        type: CoinEntryType.available,
        createdAt: createdAt,
      ),
      CoinLedgerEntry(
        id: '3',
        amount: 3,
        type: CoinEntryType.spent,
        createdAt: createdAt,
      ),
    ]);

    expect(balances.pendingTotal, 15);
    expect(balances.availableTotal, 7);
    expect(balances.total, 22);
  });
}
