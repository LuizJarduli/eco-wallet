import 'package:eco_wallet/features/wallet/domain/entities/coin_wallet.dart';

class CoinWalletModel {
  const CoinWalletModel({
    required this.userId,
    required this.pendingBalance,
    required this.availableBalance,
    required this.updatedAt,
  });

  factory CoinWalletModel.fromJson(Map<String, dynamic> json) {
    return CoinWalletModel(
      userId: json['user_id'] as String,
      pendingBalance: (json['pending_balance'] as num).toInt(),
      availableBalance: (json['available_balance'] as num).toInt(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String userId;
  final int pendingBalance;
  final int availableBalance;
  final DateTime updatedAt;

  CoinWallet toEntity() {
    return CoinWallet(
      userId: userId,
      pendingBalance: pendingBalance,
      availableBalance: availableBalance,
      updatedAt: updatedAt,
    );
  }
}
