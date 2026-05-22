"use client";

import type { AdminDisposalItem } from "@/core/lib/admin-api";
import { DisposalPhoto } from "@/features/admin-disposals/components/disposal-photo";
import {
  disposalPhotoPlaceholderPath,
  disposalStatusLabels,
  reviewPriorityLabels
} from "@/features/admin-disposals/constants";

interface SubmissionCardProps {
  submission: AdminDisposalItem;
  photoUrl?: string | null;
  children?: React.ReactNode;
}

const formatScore = (value: number | null) =>
  value === null ? "—" : `${Math.round(value * 100)}%`;

export const SubmissionCard = ({
  submission,
  photoUrl,
  children
}: SubmissionCardProps) => (
  <article className="rounded-xl border border-zinc-200 bg-white p-4 shadow-sm">
    <header className="mb-3 flex flex-wrap items-center justify-between gap-2">
      <div>
        <h3 className="text-base font-semibold text-zinc-900">
          Descarte {submission.id.slice(0, 8)}
        </h3>
        <p className="text-sm text-zinc-700">
          Enviado em {new Date(submission.submittedAt).toLocaleString("pt-BR")}
        </p>
      </div>
      <div className="flex flex-wrap gap-2 text-xs">
        <span className="rounded-full bg-zinc-100 px-2 py-1 font-medium text-zinc-700">
          {disposalStatusLabels[submission.status]}
        </span>
        <span className="rounded-full bg-amber-50 px-2 py-1 font-medium text-amber-800">
          Prioridade {reviewPriorityLabels[submission.reviewPriority]}
        </span>
      </div>
    </header>

    <div className="grid gap-4 md:grid-cols-[180px_1fr]">
      <div className="overflow-hidden rounded-lg border border-zinc-200 bg-zinc-50">
        <DisposalPhoto
          photoUrl={photoUrl ?? disposalPhotoPlaceholderPath}
        />
      </div>

      <dl className="grid grid-cols-2 gap-3 text-sm">
        <div>
          <dt className="font-medium text-zinc-700">Confiança (óleo)</dt>
          <dd className="font-medium text-zinc-900">
            {formatScore(submission.oilScore)}
          </dd>
        </div>
        <div>
          <dt className="font-medium text-zinc-700">Confiança (local)</dt>
          <dd className="font-medium text-zinc-900">
            {formatScore(submission.locationScore)}
          </dd>
        </div>
        <div>
          <dt className="font-medium text-zinc-700">Status da análise</dt>
          <dd className="font-medium text-zinc-900">{submission.confidenceStatus}</dd>
        </div>
        <div>
          <dt className="font-medium text-zinc-700">Litros estimados</dt>
          <dd className="font-medium text-zinc-900">
            {submission.estimatedLiters ?? "—"}
          </dd>
        </div>
      </dl>
    </div>

    {children ? <div className="mt-4 border-t border-zinc-100 pt-4">{children}</div> : null}
  </article>
);
