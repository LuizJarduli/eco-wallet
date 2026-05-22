"use client";

import { useState } from "react";

import { AdminApiError } from "@/core/lib/admin-api";
import { ApiErrorBanner } from "@/core/ui/api-error-banner";
import {
  buttonSuccessClassName,
  formFieldClassName,
  formLabelClassName
} from "@/core/ui/form-controls";

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
        <span className={formLabelClassName}>Litros coletados</span>
        <input
          type="number"
          min={0.1}
          step={0.1}
          className={formFieldClassName}
          value={auditedLiters}
          onChange={(event) => setAuditedLiters(event.target.value)}
        />
      </label>

      <ApiErrorBanner code={apiError?.code} message={apiError?.message} />

      <button
        type="submit"
        disabled={isSubmitting}
        className={buttonSuccessClassName}
      >
        {isSubmitting ? "Auditando..." : "Confirmar coleta e liberar moedas"}
      </button>
    </form>
  );
};
