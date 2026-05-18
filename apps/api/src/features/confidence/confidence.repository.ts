import { AppError } from "../../core/errors/app-error.js";
import {
  createSupabaseServiceClient,
  type SupabaseServiceClient
} from "../../core/supabase/service-client.js";
import type {
  ConfidenceRepository,
  ConfidenceResult,
  ConfidenceSubmission,
  DropOffPoint,
  DuplicateCandidate
} from "./confidence.types.js";

interface SupabaseErrorLike {
  message: string;
}

interface SubmissionRow {
  capture_latitude: string | number | null;
  capture_longitude: string | number | null;
  confidence_provider: string | null;
  confidence_raw: Record<string, unknown> | null;
  confidence_status: ConfidenceSubmission["confidenceStatus"];
  drop_off_id: string;
  id: string;
  location_score: string | number | null;
  oil_score: string | number | null;
  review_priority: ConfidenceSubmission["reviewPriority"];
  storage_path: string;
  submitted_at: string;
  user_id: string;
}

interface DropOffPointRow {
  active: boolean;
  id: string;
  latitude: string | number;
  longitude: string | number;
}

interface DuplicateRow {
  id: string;
  submitted_at: string;
}

const toNumber = (value: string | number | null): number | null => {
  if (value === null) {
    return null;
  }

  return typeof value === "number" ? value : Number(value);
};

const toSubmission = (row: SubmissionRow): ConfidenceSubmission => ({
  captureLat: toNumber(row.capture_latitude),
  captureLng: toNumber(row.capture_longitude),
  confidenceStatus: row.confidence_status,
  dropOffId: row.drop_off_id,
  id: row.id,
  locationScore: toNumber(row.location_score),
  oilScore: toNumber(row.oil_score),
  provider: row.confidence_provider,
  raw: row.confidence_raw,
  reviewPriority: row.review_priority,
  storagePath: row.storage_path,
  submittedAt: row.submitted_at,
  userId: row.user_id
});

const toDropOffPoint = (row: DropOffPointRow): DropOffPoint => ({
  active: row.active,
  id: row.id,
  latitude: Number(row.latitude),
  longitude: Number(row.longitude)
});

const throwPersistenceError = (error: SupabaseErrorLike): never => {
  if (error.message.includes("DISPOSAL_NOT_FOUND")) {
    throw new AppError(
      "DISPOSAL_NOT_FOUND",
      404,
      "Disposal submission was not found."
    );
  }

  throw new AppError(
    "INTERNAL_ERROR",
    500,
    "Confidence persistence operation failed."
  );
};

const submissionColumns = [
  "id",
  "user_id",
  "drop_off_id",
  "storage_path",
  "confidence_status",
  "oil_score",
  "location_score",
  "review_priority",
  "confidence_provider",
  "confidence_raw",
  "submitted_at",
  "capture_latitude",
  "capture_longitude"
].join(",");

export class SupabaseConfidenceRepository implements ConfidenceRepository {
  constructor(
    private readonly client: SupabaseServiceClient = createSupabaseServiceClient(),
    private readonly bucketName = "disposal-photos",
    private readonly signedUrlExpiresInSeconds = 600
  ) {}

  async createSignedImageUrl(storagePath: string): Promise<string> {
    const { data, error } = await this.client.storage
      .from(this.bucketName)
      .createSignedUrl(storagePath, this.signedUrlExpiresInSeconds);

    if (error || !data?.signedUrl) {
      throw new AppError(
        "INTERNAL_ERROR",
        500,
        "Could not create a signed disposal photo URL."
      );
    }

    return data.signedUrl;
  }

  async findSubmission(
    submissionId: string
  ): Promise<ConfidenceSubmission | null> {
    const { data, error } = await this.client
      .from("disposal_submissions")
      .select(submissionColumns)
      .eq("id", submissionId)
      .maybeSingle<SubmissionRow>();

    if (error) {
      throwPersistenceError(error);
    }

    return data ? toSubmission(data) : null;
  }

  async findDropOffPoint(dropOffId: string): Promise<DropOffPoint | null> {
    const { data, error } = await this.client
      .from("drop_off_points")
      .select("id,active,latitude,longitude")
      .eq("id", dropOffId)
      .maybeSingle<DropOffPointRow>();

    if (error) {
      throwPersistenceError(error);
    }

    return data ? toDropOffPoint(data) : null;
  }

  async findRecentDuplicate(input: {
    excludeSubmissionId: string;
    storagePath: string;
    submittedAfter: string;
    userId: string;
  }): Promise<DuplicateCandidate | null> {
    const { data, error } = await this.client
      .from("disposal_submissions")
      .select("id,submitted_at")
      .eq("user_id", input.userId)
      .eq("storage_path", input.storagePath)
      .neq("id", input.excludeSubmissionId)
      .gte("submitted_at", input.submittedAfter)
      .order("submitted_at", { ascending: false })
      .limit(1)
      .maybeSingle<DuplicateRow>();

    if (error) {
      throwPersistenceError(error);
    }

    return data
      ? {
          id: data.id,
          submittedAt: data.submitted_at
        }
      : null;
  }

  async markReady(
    submissionId: string,
    result: ConfidenceResult
  ): Promise<ConfidenceSubmission> {
    return this.updateConfidence(submissionId, {
      confidence_provider: result.provider,
      confidence_raw: result.raw ?? null,
      confidence_status: "ready",
      location_score: result.locationScore,
      oil_score: result.oilScore,
      review_priority: result.reviewPriority
    });
  }

  async markFailed(
    submissionId: string,
    metadata: Record<string, unknown>
  ): Promise<ConfidenceSubmission> {
    return this.updateConfidence(submissionId, {
      confidence_provider: "vision-api",
      confidence_raw: metadata,
      confidence_status: "failed",
      location_score: null,
      oil_score: null,
      review_priority: "normal"
    });
  }

  private async updateConfidence(
    submissionId: string,
    values: {
      confidence_provider: string;
      confidence_raw: Record<string, unknown> | null;
      confidence_status: ConfidenceSubmission["confidenceStatus"];
      location_score: number | null;
      oil_score: number | null;
      review_priority: ConfidenceSubmission["reviewPriority"];
    }
  ): Promise<ConfidenceSubmission> {
    const { data, error } = await this.client
      .from("disposal_submissions")
      .update(values)
      .eq("id", submissionId)
      .select(submissionColumns)
      .single<SubmissionRow>();

    if (error) {
      throwPersistenceError(error);
    }

    if (!data) {
      throwPersistenceError({ message: "DISPOSAL_NOT_FOUND" });
    }

    return toSubmission(data as SubmissionRow);
  }
}
