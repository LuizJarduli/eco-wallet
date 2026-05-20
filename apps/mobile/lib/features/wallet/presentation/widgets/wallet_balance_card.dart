import 'package:flutter/material.dart';

import 'package:eco_wallet/core/theme/app_colors.dart';
import 'package:eco_wallet/features/wallet/domain/entities/coin_wallet.dart';

class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    required this.wallet,
    required this.onGetMoreCoins,
    required this.onHowToEarn,
    super.key,
  });

  final CoinWallet wallet;
  final VoidCallback onGetMoreCoins;
  final VoidCallback onHowToEarn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.walletCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo EcoCoin',
            style: TextStyle(color: AppColors.onDarkMuted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.onDark,
                fontSize: 36,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(text: '${wallet.totalBalance} '),
                const TextSpan(
                  text: 'EC',
                  style: TextStyle(color: AppColors.rewardCoral),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BalanceChip(
                  label: 'Disponível',
                  value: wallet.availableBalance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BalanceChip(
                  label: 'Pendente',
                  value: wallet.pendingBalance,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onGetMoreCoins,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Ganhar mais moedas'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onHowToEarn,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onDark,
                side: const BorderSide(color: AppColors.onDarkMuted),
              ),
              child: const Text('Como ganhar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.heroDarkFrom.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.onDarkMuted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            '$value EC',
            style: const TextStyle(
              color: AppColors.onDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
