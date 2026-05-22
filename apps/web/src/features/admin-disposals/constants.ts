import type { DisposalStatus, RejectionReasonCode } from "@eco-wallet/domain";

import type { ReviewPriority } from "@/core/lib/admin-api";

export const disposalStatusLabels: Record<DisposalStatus, string> = {
  submitted: "Enviado",
  under_review: "Em análise",
  approved: "Aprovado",
  awaiting_audit: "Aguardando auditoria",
  rewarded: "Recompensado",
  rejected: "Rejeitado"
};

export const reviewPriorityLabels: Record<ReviewPriority, string> = {
  low: "Baixa",
  normal: "Normal",
  high: "Alta"
};

export const rejectionReasonLabels: Record<RejectionReasonCode, string> = {
  not_oil: "Não é óleo de cozinha usado",
  unclear_photo: "Foto ilegível",
  bottle_not_visible: "Garrafa não visível",
  below_min_volume: "Volume abaixo de um litro",
  invalid_drop_off: "Ponto de descarte inválido",
  duplicate: "Descarte duplicado",
  other: "Outro"
};

/** Static fallback when Supabase storage has no file for the submission path. */
export const disposalPhotoPlaceholderPath = "/placeholders/disposal-oil-bottle.jpg";

export const domainErrorMessages: Record<string, string> = {
  BELOW_MIN_VOLUME:
    "O volume auditado está abaixo do mínimo exigido pelas regras ativas.",
  INVALID_TRANSITION: "Este descarte não pode mudar de status agora.",
  DISPOSAL_NOT_FOUND: "Descarte não encontrado.",
  VALIDATION_ERROR: "Revise os dados informados.",
  UNAUTHORIZED: "Sessão expirada. Entre novamente.",
  FORBIDDEN: "Você não tem permissão para esta ação.",
  INTERNAL_ERROR: "Erro interno. Tente novamente em instantes."
};
