import 'package:eco_wallet/features/rewards/domain/entities/scratch_play_result.dart';

String scratchDiscountLabel(ScratchPlayResult result) {
  return '${result.discountPercent}% de desconto';
}

String scratchRedemptionCopy(ScratchPlayResult result) {
  return switch (result.discountPercent) {
    10 =>
      'Parabéns! Você ganhou 10% de desconto na parcela do seu próximo pedido no campus.',
    _ =>
      'Você ganhou 5% de desconto na parcela do seu próximo pedido no campus.',
  };
}

String scratchBadgeLabel(ScratchPlayResult result) {
  return result.isRare ? 'Premium' : 'Oferta quente';
}
