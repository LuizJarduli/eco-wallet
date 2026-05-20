"use client";

import { rejectionReasonCodes, type RejectionReasonCode } from "@eco-wallet/domain";
import { useState } from "react";

import { ApiErrorBanner } from "@/core/ui/api-error-banner";
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
        <span className="font-medium text-zinc-700">Motivo da rejeição</span>
        <select
          aria-label="Motivo da rejeição"
          className="rounded-md border border-zinc-300 bg-white px-3 py-2"
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
        <span className="font-medium text-zinc-700">Observação (opcional)</span>
        <textarea
          className="min-h-20 rounded-md border border-zinc-300 px-3 py-2"
          value={note}
          onChange={(event) => setNote(event.target.value)}
          maxLength={500}
        />
      </label>

      <ApiErrorBanner code={errorCode} message={errorMessage} />

      <button
        type="submit"
        disabled={!reasonCode || isSubmitting}
        className="rounded-md bg-red-700 px-4 py-2 text-sm font-medium text-white disabled:cursor-not-allowed disabled:bg-red-300"
      >
        {isSubmitting ? "Rejeitando..." : "Rejeitar descarte"}
      </button>
    </form>
  );
};
