import 'package:eco_wallet/features/wallet/domain/entities/coin_ledger_entry.dart';

class CoinLedgerEntryModel {
  const CoinLedgerEntryModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.referenceId,
  });

  factory CoinLedgerEntryModel.fromJson(Map<String, dynamic> json) {
    return CoinLedgerEntryModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
      type: _parseType(json['type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      referenceId: json['reference_id'] as String?,
    );
  }

  final String id;
  final int amount;
  final CoinEntryType type;
  final DateTime createdAt;
  final String? referenceId;

  CoinLedgerEntry toEntity() {
    return CoinLedgerEntry(
      id: id,
      amount: amount,
      type: type,
      createdAt: createdAt,
      referenceId: referenceId,
    );
  }

  static CoinEntryType _parseType(String raw) {
    return switch (raw) {
      'pending' => CoinEntryType.pending,
      'available' => CoinEntryType.available,
      'spent' => CoinEntryType.spent,
      _ => CoinEntryType.pending,
    };
  }
}
