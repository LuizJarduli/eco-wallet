import type { RejectionReasonCode } from "@eco-wallet/domain";

export const rejectionDeepLink = "ecowallet://disposal/submit";

export const rejectionPushTitle = "Descarte não aprovado";

export const rejectionReasonSummary = (
  reasonCode: RejectionReasonCode
): string => {
  const summaries: Record<RejectionReasonCode, string> = {
    not_oil: "A foto não parece ser de óleo de cozinha usado.",
    unclear_photo: "A foto está ilegível ou muito escura.",
    bottle_not_visible: "A garrafa não está visível na foto.",
    below_min_volume: "O volume informado está abaixo do mínimo.",
    invalid_drop_off: "O ponto de descarte selecionado não é válido.",
    duplicate: "Este descarte já foi registrado.",
    other: "Não foi possível aprovar este descarte."
  };

  return summaries[reasonCode];
};

export const rejectionPushBody = (reasonCode: RejectionReasonCode): string =>
  `${rejectionReasonSummary(reasonCode)} Toque para enviar um novo descarte.`;
