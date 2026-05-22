import 'package:equatable/equatable.dart';

class CoinWallet extends Equatable {
  const CoinWallet({
    required this.userId,
    required this.pendingBalance,
    required this.availableBalance,
    required this.updatedAt,
  });

  final String userId;
  final int pendingBalance;
  final int availableBalance;
  final DateTime updatedAt;

  int get totalBalance => pendingBalance + availableBalance;

  @override
  List<Object?> get props => [
    userId,
    pendingBalance,
    availableBalance,
    updatedAt,
  ];
}
