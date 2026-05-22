/* eslint-disable react-hooks/set-state-in-effect -- queue reloads from async API responses */
"use client";

import type { DisposalStatus } from "@eco-wallet/domain";
import { useCallback, useEffect, useMemo, useState } from "react";

import {
  AdminApiError,
  approveDisposal,
  listAdminDisposals,
  rejectDisposal,
  type AdminDisposalItem,
  type ReviewPriority
} from "@/core/lib/admin-api";
import { buttonSecondaryClassName } from "@/core/ui/form-controls";
import { ApproveForm } from "@/features/admin-disposals/components/approve-form";
import {
  QueueFilters,
  type QueueFiltersValue
} from "@/features/admin-disposals/components/queue-filters";
import { RejectForm } from "@/features/admin-disposals/components/reject-form";
import { SubmissionCard } from "@/features/admin-disposals/components/submission-card";
import {
  buildPhotoUrl,
  useStoragePaths
} from "@/features/admin-disposals/hooks/use-storage-paths";

interface VerificationQueueProps {
  accessToken: string;
}

export const VerificationQueue = ({ accessToken }: VerificationQueueProps) => {
  const [filters, setFilters] = useState<QueueFiltersValue>({
    status: "submitted",
    priority: ""
  });
  const [items, setItems] = useState<AdminDisposalItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [listError, setListError] = useState<string | null>(null);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [actionError, setActionError] = useState<{
    code?: string;
    message?: string;
  } | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const loadQueue = useCallback(async () => {
    setLoading(true);
    setListError(null);

    try {
      const data = await listAdminDisposals(accessToken, {
        status: filters.status
          ? (filters.status as DisposalStatus)
          : undefined,
        priority: filters.priority
          ? (filters.priority as ReviewPriority)
          : undefined
      });
      setItems(data);
    } catch (error) {
      const message =
        error instanceof AdminApiError
          ? error.message
          : "Não foi possível carregar a fila.";
      setListError(message);
      setItems([]);
    } finally {
      setLoading(false);
    }
  }, [accessToken, filters.priority, filters.status]);

  useEffect(() => {
    void loadQueue();
  }, [loadQueue]);

  const submissionIds = useMemo(() => items.map((item) => item.id), [items]);
  const storagePaths = useStoragePaths(submissionIds);

  return (
    <div className="flex flex-col gap-6">
      <QueueFilters value={filters} onFilterChange={setFilters} />

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

      {loading ? <p className="text-sm text-zinc-600">Carregando fila...</p> : null}

      {!loading && items.length === 0 ? (
        <p className="text-sm text-zinc-600">Nenhum descarte encontrado para os filtros.</p>
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
          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              className={buttonSecondaryClassName}
              onClick={() => {
                setActiveId((current) =>
                  current === submission.id ? null : submission.id
                );
                setActionError(null);
                setSuccessMessage(null);
              }}
            >
              {activeId === submission.id ? "Fechar ações" : "Revisar"}
            </button>
          </div>

          {activeId === submission.id ? (
            <div className="mt-4 grid gap-6 lg:grid-cols-2">
              <ApproveForm
                isSubmitting={isSubmitting}
                errorCode={actionError?.code}
                errorMessage={actionError?.message}
                onSubmit={async (estimatedLiters) => {
                  setIsSubmitting(true);
                  setActionError(null);
                  setSuccessMessage(null);

                  try {
                    await approveDisposal(
                      accessToken,
                      submission.id,
                      estimatedLiters
                    );
                    setSuccessMessage("Descarte aprovado e enviado para auditoria.");
                    setActiveId(null);
                    await loadQueue();
                  } catch (error) {
                    setActionError({
                      code: error instanceof AdminApiError ? error.code : undefined,
                      message:
                        error instanceof Error
                          ? error.message
                          : "Não foi possível aprovar."
                    });
                  } finally {
                    setIsSubmitting(false);
                  }
                }}
              />

              <RejectForm
                isSubmitting={isSubmitting}
                errorCode={actionError?.code}
                errorMessage={actionError?.message}
                onSubmit={async ({ reasonCode, note }) => {
                  setIsSubmitting(true);
                  setActionError(null);
                  setSuccessMessage(null);

                  try {
                    await rejectDisposal(
                      accessToken,
                      submission.id,
                      reasonCode,
                      note
                    );
                    setSuccessMessage("Descarte rejeitado com sucesso.");
                    setActiveId(null);
                    await loadQueue();
                  } catch (error) {
                    setActionError({
                      code: error instanceof AdminApiError ? error.code : undefined,
                      message:
                        error instanceof Error
                          ? error.message
                          : "Não foi possível rejeitar."
                    });
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
