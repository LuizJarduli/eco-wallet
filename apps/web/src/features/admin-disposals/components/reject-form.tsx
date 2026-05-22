"use client";

import { rejectionReasonCodes, type RejectionReasonCode } from "@eco-wallet/domain";
import { useState } from "react";

import { ApiErrorBanner } from "@/core/ui/api-error-banner";
import {
  buttonDangerClassName,
  formFieldClassName,
  formLabelClassName,
  formTextareaClassName
} from "@/core/ui/form-controls";
import { rejectionReasonLabels } from "@/features/admin-disposals/constants";

interface RejectFormProps {
  onSubmit: (input: { reasonCode: RejectionReasonCode; note?: string }) => Promise<void>;
  isSubmitting?: boolean;
  errorCode?: string;
  errorMessage?: string;
}

export const RejectForm = ({
  onSubmit,
  isSubmitting = false,
  errorCode,
  errorMessage
}: RejectFormProps) => {
  const [reasonCode, setReasonCode] = useState<RejectionReasonCode | "">("");
  const [note, setNote] = useState("");

  return (
    <form
      className="flex flex-col gap-3"
      onSubmit={async (event) => {
        event.preventDefault();

        if (!reasonCode) {
          return;
        }

        await onSubmit({
          reasonCode,
          note: note.trim() ? note.trim() : undefined
        });
      }}
    >
      <label className="flex flex-col gap-1 text-sm">
        <span className={formLabelClassName}>Motivo da rejeição</span>
        <select
          aria-label="Motivo da rejeição"
          className={formFieldClassName}
          value={reasonCode}
          onChange={(event) =>
            setReasonCode(event.target.value as RejectionReasonCode | "")
          }
        >
          <option value="">Selecione um motivo</option>
          {rejectionReasonCodes.map((code) => (
            <option key={code} value={code}>
              {rejectionReasonLabels[code]}
            </option>
          ))}
        </select>
      </label>

      <label className="flex flex-col gap-1 text-sm">
        <span className={formLabelClassName}>Observação (opcional)</span>
        <textarea
          className={formTextareaClassName}
          value={note}
          onChange={(event) => setNote(event.target.value)}
          maxLength={500}
        />
      </label>

      <ApiErrorBanner code={errorCode} message={errorMessage} />

      <button
        type="submit"
        disabled={!reasonCode || isSubmitting}
        className={buttonDangerClassName}
      >
        {isSubmitting ? "Rejeitando..." : "Rejeitar descarte"}
      </button>
    </form>
  );
};
