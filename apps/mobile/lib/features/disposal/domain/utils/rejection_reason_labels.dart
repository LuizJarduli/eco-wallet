import 'package:eco_wallet/features/disposal/domain/entities/rejection_reason.dart';

String rejectionReasonLabel(RejectionReasonCode reason) {
  return switch (reason) {
    RejectionReasonCode.notOil =>
      'A foto não parece ser de óleo de cozinha usado.',
    RejectionReasonCode.unclearPhoto =>
      'A foto está ilegível ou muito escura.',
    RejectionReasonCode.bottleNotVisible =>
      'A garrafa não está visível na foto.',
    RejectionReasonCode.belowMinVolume =>
      'O volume informado está abaixo do mínimo.',
    RejectionReasonCode.invalidDropOff =>
      'O ponto de descarte selecionado não é válido.',
    RejectionReasonCode.duplicate => 'Este descarte já foi registrado.',
    RejectionReasonCode.other => 'Não foi possível aprovar este descarte.',
  };
}

RejectionReasonCode? parseRejectionReasonCode(String? raw) {
  if (raw == null) {
    return null;
  }
  return switch (raw) {
    'not_oil' => RejectionReasonCode.notOil,
    'unclear_photo' => RejectionReasonCode.unclearPhoto,
    'bottle_not_visible' => RejectionReasonCode.bottleNotVisible,
    'below_min_volume' => RejectionReasonCode.belowMinVolume,
    'invalid_drop_off' => RejectionReasonCode.invalidDropOff,
    'duplicate' => RejectionReasonCode.duplicate,
    'other' => RejectionReasonCode.other,
    _ => null,
  };
}
