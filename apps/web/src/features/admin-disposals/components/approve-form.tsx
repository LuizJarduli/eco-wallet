"use client";

import { useState } from "react";

import { ApiErrorBanner } from "@/core/ui/api-error-banner";

interface ApproveFormProps {
  onSubmit: (estimatedLiters: number) => Promise<void>;
  isSubmitting?: boolean;
  errorCode?: string;
  errorMessage?: string;
}

export const ApproveForm = ({
  onSubmit,
  isSubmitting = false,
  errorCode,
  errorMessage
}: ApproveFormProps) => {
  const [estimatedLiters, setEstimatedLiters] = useState("1");

  return (
    <form
      className="flex flex-col gap-3"
      onSubmit={async (event) => {
        event.preventDefault();
        const liters = Number(estimatedLiters);

        if (!Number.isFinite(liters) || liters <= 0) {
          return;
        }

        await onSubmit(liters);
      }}
    >
      <label className="flex flex-col gap-1 text-sm">
        <span className="font-medium text-zinc-700">Litros estimados</span>
        <input
          type="number"
          min={0.1}
          step={0.1}
          className="rounded-md border border-zinc-300 px-3 py-2"
          value={estimatedLiters}
          onChange={(event) => setEstimatedLiters(event.target.value)}
        />
      </label>

      <ApiErrorBanner code={errorCode} message={errorMessage} />

      <button
        type="submit"
        disabled={isSubmitting}
        className="rounded-md bg-emerald-700 px-4 py-2 text-sm font-medium text-white disabled:cursor-not-allowed disabled:bg-emerald-300"
      >
        {isSubmitting ? "Aprovando..." : "Aprovar descarte"}
      </button>
    </form>
  );
};
