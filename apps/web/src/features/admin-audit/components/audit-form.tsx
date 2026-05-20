"use client";

import { useState } from "react";

import { AdminApiError } from "@/core/lib/admin-api";
import { ApiErrorBanner } from "@/core/ui/api-error-banner";

interface AuditFormProps {
  onSubmit: (auditedLiters: number) => Promise<void>;
  isSubmitting?: boolean;
  apiError?: AdminApiError | null;
}

export const AuditForm = ({
  onSubmit,
  isSubmitting = false,
  apiError = null
}: AuditFormProps) => {
  const [auditedLiters, setAuditedLiters] = useState("1");

  return (
    <form
      className="flex flex-col gap-3"
      onSubmit={async (event) => {
        event.preventDefault();
        const liters = Number(auditedLiters);

        if (!Number.isFinite(liters) || liters <= 0) {
          return;
        }

        await onSubmit(liters);
      }}
    >
      <label className="flex flex-col gap-1 text-sm">
        <span className="font-medium text-zinc-700">Litros coletados</span>
        <input
          type="number"
          min={0.1}
          step={0.1}
          className="rounded-md border border-zinc-300 px-3 py-2"
          value={auditedLiters}
          onChange={(event) => setAuditedLiters(event.target.value)}
        />
      </label>

      <ApiErrorBanner code={apiError?.code} message={apiError?.message} />

      <button
        type="submit"
        disabled={isSubmitting}
        className="rounded-md bg-emerald-700 px-4 py-2 text-sm font-medium text-white disabled:cursor-not-allowed disabled:bg-emerald-300"
      >
        {isSubmitting ? "Auditando..." : "Confirmar coleta e liberar moedas"}
      </button>
    </form>
  );
};
