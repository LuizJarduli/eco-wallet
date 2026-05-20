import 'package:equatable/equatable.dart';

enum CoinEntryType { pending, available, spent }

class CoinLedgerEntry extends Equatable {
  const CoinLedgerEntry({
    required this.id,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.referenceId,
  });

  final String id;
  final int amount;
  final CoinEntryType type;
  final DateTime createdAt;
  final String? referenceId;

  @override
  List<Object?> get props => [id, amount, type, createdAt, referenceId];
}
