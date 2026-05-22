/* eslint-disable react-hooks/set-state-in-effect -- queue reloads from async API responses */
"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import {
  AdminApiError,
  auditDisposal,
  listAdminDisposals,
  type AdminDisposalItem
} from "@/core/lib/admin-api";
import { buttonSecondaryClassName } from "@/core/ui/form-controls";
import { AuditForm } from "@/features/admin-audit/components/audit-form";
import { SubmissionCard } from "@/features/admin-disposals/components/submission-card";
import {
  buildPhotoUrl,
  useStoragePaths
} from "@/features/admin-disposals/hooks/use-storage-paths";

interface AuditQueueProps {
  accessToken: string;
}

export const AuditQueue = ({ accessToken }: AuditQueueProps) => {
  const [items, setItems] = useState<AdminDisposalItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [listError, setListError] = useState<string | null>(null);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [apiError, setApiError] = useState<AdminApiError | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const loadQueue = useCallback(async () => {
    setLoading(true);
    setListError(null);

    try {
      const data = await listAdminDisposals(accessToken, {
        status: "awaiting_audit"
      });
      setItems(data);
    } catch (error) {
      const message =
        error instanceof AdminApiError
          ? error.message
          : "Não foi possível carregar a fila de auditoria.";
      setListError(message);
      setItems([]);
    } finally {
      setLoading(false);
    }
  }, [accessToken]);

  useEffect(() => {
    void loadQueue();
  }, [loadQueue]);

  const submissionIds = useMemo(() => items.map((item) => item.id), [items]);
  const storagePaths = useStoragePaths(submissionIds);

  return (
    <div className="flex flex-col gap-6">
      {successMessage ? (
        <p
          role="status"
          className="rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800"
        >
          {successMessage}
        </p>
      ) : null}

      {listError ? (
        <p role="alert" className="text-sm text-red-700">
          {listError}
        </p>
      ) : null}

      {loading ? <p className="text-sm text-zinc-600">Carregando auditoria...</p> : null}

      {!loading && items.length === 0 ? (
        <p className="text-sm text-zinc-600">
          Nenhum descarte aguardando auditoria de coleta.
        </p>
      ) : null}

      {items.map((submission) => (
        <SubmissionCard
          key={submission.id}
          submission={submission}
          photoUrl={
            storagePaths[submission.id]
              ? buildPhotoUrl(storagePaths[submission.id])
              : null
          }
        >
          <button
            type="button"
            className={buttonSecondaryClassName}
            onClick={() => {
              setActiveId((current) =>
                current === submission.id ? null : submission.id
              );
              setApiError(null);
              setSuccessMessage(null);
            }}
          >
            {activeId === submission.id ? "Fechar auditoria" : "Auditar coleta"}
          </button>

          {activeId === submission.id ? (
            <div className="mt-4 max-w-md">
              <AuditForm
                isSubmitting={isSubmitting}
                apiError={apiError}
                onSubmit={async (auditedLiters) => {
                  setIsSubmitting(true);
                  setApiError(null);
                  setSuccessMessage(null);

                  try {
                    const result = await auditDisposal(
                      accessToken,
                      submission.id,
                      auditedLiters
                    );
                    setSuccessMessage(
                      `Coleta auditada. ${result.coinsReleased} moedas liberadas.`
                    );
                    setActiveId(null);
                    await loadQueue();
                  } catch (error) {
                    setApiError(
                      error instanceof AdminApiError
                        ? error
                        : new AdminApiError(
                            "INTERNAL_ERROR",
                            "Não foi possível concluir a auditoria."
                          )
                    );
                  } finally {
                    setIsSubmitting(false);
                  }
                }}
              />
            </div>
          ) : null}
        </SubmissionCard>
      ))}
    </div>
  );
};
