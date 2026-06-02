import {
  apiErrorResponseSchema,
  type ApiErrorResponse,
  type DisposalStatus,
  type RejectionReasonCode
} from "@eco-wallet/domain";

import { publicEnv } from "@/core/config/env";

export type ReviewPriority = "low" | "normal" | "high";

export interface AdminDisposalItem {
  id: string;
  userId: string;
  status: DisposalStatus;
  rejectionReason: RejectionReasonCode | null;
  estimatedLiters: number | null;
  confidenceStatus: string;
  oilScore: number | null;
  locationScore: number | null;
  reviewPriority: ReviewPriority;
  submittedAt: string;
  updatedAt: string;
  storagePath: string;
}

export interface ListAdminDisposalsFilters {
  status?: DisposalStatus;
  priority?: ReviewPriority;
}

export class AdminApiError extends Error {
  constructor(
    readonly code: string,
    message: string
  ) {
    super(message);
    this.name = "AdminApiError";
  }
}

const parseApiError = async (response: Response): Promise<AdminApiError> => {
  try {
    const body = (await response.json()) as ApiErrorResponse;
    const parsed = apiErrorResponseSchema.safeParse(body);

    if (parsed.success) {
      return new AdminApiError(
        parsed.data.error.code,
        parsed.data.error.message
      );
    }
  } catch {
    // Fall through to generic error.
  }

  return new AdminApiError(
    "INTERNAL_ERROR",
    "Não foi possível concluir a operação."
  );
};

const request = async <T>(
  path: string,
  accessToken: string,
  init?: RequestInit
): Promise<T> => {
  const response = await fetch(`${publicEnv.apiBaseUrl()}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
      ...(init?.headers ?? {})
    }
  });

  if (!response.ok) {
    throw await parseApiError(response);
  }

  if (response.status === 204) {
    return undefined as T;
  }

  const body = (await response.json()) as { data: T };
  return body.data;
};

export const listAdminDisposals = (
  accessToken: string,
  filters: ListAdminDisposalsFilters
): Promise<AdminDisposalItem[]> => {
  const params = new URLSearchParams();

  if (filters.status) {
    params.set("status", filters.status);
  }

  if (filters.priority) {
    params.set("priority", filters.priority);
  }

  const query = params.toString();
  const suffix = query ? `?${query}` : "";

  return request<AdminDisposalItem[]>(
    `/v1/admin/disposals${suffix}`,
    accessToken
  );
};

export const approveDisposal = (
  accessToken: string,
  submissionId: string,
  estimatedLiters: number
) =>
  request<{ pendingCoins: number }>(
    `/v1/admin/disposals/${submissionId}/approve`,
    accessToken,
    {
      method: "POST",
      body: JSON.stringify({ estimatedLiters })
    }
  );

export const rejectDisposal = (
  accessToken: string,
  submissionId: string,
  reasonCode: RejectionReasonCode,
  note?: string
) =>
  request<void>(`/v1/admin/disposals/${submissionId}/reject`, accessToken, {
    method: "POST",
    body: JSON.stringify({ reasonCode, note })
  });

export const auditDisposal = (
  accessToken: string,
  submissionId: string,
  auditedLiters: number
) =>
  request<{ coinsReleased: number }>(
    `/v1/admin/disposals/${submissionId}/audit`,
    accessToken,
    {
      method: "POST",
      body: JSON.stringify({ auditedLiters })
    }
  );
