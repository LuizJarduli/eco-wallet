import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';

String disposalStatusLabel(DisposalStatus status) {
  return switch (status) {
    DisposalStatus.submitted => 'Enviado',
    DisposalStatus.underReview => 'Em verificação',
    DisposalStatus.approved => 'Aprovado',
    DisposalStatus.awaitingAudit => 'Aguardando auditoria',
    DisposalStatus.rewarded => 'Recompensado',
    DisposalStatus.rejected => 'Recusado',
  };
}
