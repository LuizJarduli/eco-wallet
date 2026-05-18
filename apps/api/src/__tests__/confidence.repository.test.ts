import { describe, expect, it } from "vitest";

import type { SupabaseServiceClient } from "../core/supabase/service-client.js";
import { SupabaseConfidenceRepository } from "../features/confidence/confidence.repository.js";

interface DbError {
  message: string;
}

interface DbResult<T> {
  data: T | null;
  error: DbError | null;
}

class FakeQuery<T> {
  readonly eqCalls: Array<[string, unknown]> = [];
  readonly gteCalls: Array<[string, unknown]> = [];
  readonly neqCalls: Array<[string, unknown]> = [];
  readonly updateCalls: unknown[] = [];

  constructor(private readonly result: DbResult<T>) {}

  select(_columns: string): this {
    return this;
  }

  eq(column: string, value: unknown): this {
    this.eqCalls.push([column, value]);
    return this;
  }

  neq(column: string, value: unknown): this {
    this.neqCalls.push([column, value]);
    return this;
  }

  gte(column: string, value: unknown): this {
    this.gteCalls.push([column, value]);
    return this;
  }

  order(_column: string, _options: unknown): this {
    return this;
  }

  limit(_count: number): this {
    return this;
  }

  update(values: unknown): this {
    this.updateCalls.push(values);
    return this;
  }

  async maybeSingle<U>(): Promise<DbResult<U>> {
    return this.result as unknown as DbResult<U>;
  }

  async single<U>(): Promise<DbResult<U>> {
    return this.result as unknown as DbResult<U>;
  }
}

class FakeStorageBucket {
  readonly signedUrlCalls: Array<{ expiresIn: number; path: string }> = [];

  constructor(private readonly result: DbResult<{ signedUrl: string }>) {}

  async createSignedUrl(path: string, expiresIn: number) {
    this.signedUrlCalls.push({ expiresIn, path });
    return this.result;
  }
}

class FakeStorage {
  constructor(private readonly bucket: FakeStorageBucket) {}

  from(_bucketName: string): FakeStorageBucket {
    return this.bucket;
  }
}

class FakeSupabaseClient {
  readonly fromCalls: string[] = [];
  readonly storage: FakeStorage;

  constructor(
    private readonly queries: FakeQuery<unknown>[],
    bucket = new FakeStorageBucket({
      data: { signedUrl: "https://storage.test/photo.jpg" },
      error: null
    })
  ) {
    this.storage = new FakeStorage(bucket);
  }

  from(table: string): FakeQuery<unknown> {
    this.fromCalls.push(table);
    const query = this.queries.shift();

    if (!query) {
      throw new Error(`Unexpected table query: ${table}`);
    }

    return query;
  }
}

const createRepository = (client: FakeSupabaseClient) =>
  new SupabaseConfidenceRepository(client as unknown as SupabaseServiceClient);

const submissionRow = {
  capture_latitude: "-23.501000",
  capture_longitude: "-47.460000",
  confidence_provider: null,
  confidence_raw: null,
  confidence_status: "pending",
  drop_off_id: "drop-off-1",
  id: "submission-1",
  location_score: null,
  oil_score: null,
  review_priority: "normal",
  storage_path: "member-1/photo.jpg",
  submitted_at: "2026-05-17T20:00:00.000Z",
  user_id: "member-1"
} as const;

describe("SupabaseConfidenceRepository", () => {
  it("creates signed URLs from the disposal photos bucket", async () => {
    const bucket = new FakeStorageBucket({
      data: { signedUrl: "https://storage.test/signed.jpg" },
      error: null
    });
    const repository = createRepository(new FakeSupabaseClient([], bucket));

    await expect(repository.createSignedImageUrl("path/photo.jpg")).resolves.toBe(
      "https://storage.test/signed.jpg"
    );
    expect(bucket.signedUrlCalls).toEqual([
      { expiresIn: 600, path: "path/photo.jpg" }
    ]);
  });

  it("fails when storage cannot create a signed URL", async () => {
    const repository = createRepository(
      new FakeSupabaseClient(
        [],
        new FakeStorageBucket({
          data: null,
          error: { message: "storage unavailable" }
        })
      )
    );

    await expect(repository.createSignedImageUrl("path/photo.jpg")).rejects.toMatchObject({
      code: "INTERNAL_ERROR"
    });
  });

  it("maps submission rows for scoring", async () => {
    const query = new FakeQuery({ data: submissionRow, error: null });
    const repository = createRepository(new FakeSupabaseClient([query]));

    await expect(repository.findSubmission("submission-1")).resolves.toMatchObject({
      captureLat: -23.501,
      captureLng: -47.46,
      confidenceStatus: "pending",
      storagePath: "member-1/photo.jpg",
      userId: "member-1"
    });
    expect(query.eqCalls).toEqual([["id", "submission-1"]]);
  });

  it("returns null when a scoring submission is not found", async () => {
    const repository = createRepository(
      new FakeSupabaseClient([new FakeQuery({ data: null, error: null })])
    );

    await expect(repository.findSubmission("missing")).resolves.toBeNull();
  });

  it("maps missing submission persistence errors", async () => {
    const repository = createRepository(
      new FakeSupabaseClient([
        new FakeQuery({ data: null, error: { message: "DISPOSAL_NOT_FOUND" } })
      ])
    );

    await expect(repository.findSubmission("missing")).rejects.toMatchObject({
      code: "DISPOSAL_NOT_FOUND"
    });
  });

  it("maps active drop-off points", async () => {
    const repository = createRepository(
      new FakeSupabaseClient([
        new FakeQuery({
          data: {
            active: true,
            id: "drop-off-1",
            latitude: "-23.501000",
            longitude: "-47.460000"
          },
          error: null
        })
      ])
    );

    await expect(repository.findDropOffPoint("drop-off-1")).resolves.toEqual({
      active: true,
      id: "drop-off-1",
      latitude: -23.501,
      longitude: -47.46
    });
  });

  it("returns null when a drop-off point is absent", async () => {
    const repository = createRepository(
      new FakeSupabaseClient([new FakeQuery({ data: null, error: null })])
    );

    await expect(repository.findDropOffPoint("missing")).resolves.toBeNull();
  });

  it("queries recent duplicate submissions by user and storage path", async () => {
    const query = new FakeQuery({
      data: {
        id: "submission-0",
        submitted_at: "2026-05-17T19:55:00.000Z"
      },
      error: null
    });
    const repository = createRepository(new FakeSupabaseClient([query]));

    await expect(
      repository.findRecentDuplicate({
        excludeSubmissionId: "submission-1",
        storagePath: "member-1/photo.jpg",
        submittedAfter: "2026-05-17T19:00:00.000Z",
        userId: "member-1"
      })
    ).resolves.toEqual({
      id: "submission-0",
      submittedAt: "2026-05-17T19:55:00.000Z"
    });
    expect(query.eqCalls).toEqual([
      ["user_id", "member-1"],
      ["storage_path", "member-1/photo.jpg"]
    ]);
    expect(query.neqCalls).toEqual([["id", "submission-1"]]);
    expect(query.gteCalls).toEqual([
      ["submitted_at", "2026-05-17T19:00:00.000Z"]
    ]);
  });

  it("returns null when no recent duplicate exists", async () => {
    const repository = createRepository(
      new FakeSupabaseClient([new FakeQuery({ data: null, error: null })])
    );

    await expect(
      repository.findRecentDuplicate({
        excludeSubmissionId: "submission-1",
        storagePath: "member-1/photo.jpg",
        submittedAfter: "2026-05-17T19:00:00.000Z",
        userId: "member-1"
      })
    ).resolves.toBeNull();
  });

  it("persists ready confidence fields", async () => {
    const query = new FakeQuery({
      data: {
        ...submissionRow,
        confidence_provider: "mock",
        confidence_raw: { duplicateDetected: false },
        confidence_status: "ready",
        location_score: "1.000",
        oil_score: "0.900",
        review_priority: "high"
      },
      error: null
    });
    const repository = createRepository(new FakeSupabaseClient([query]));

    await expect(
      repository.markReady("submission-1", {
        locationScore: 1,
        oilScore: 0.9,
        provider: "mock",
        raw: { duplicateDetected: false },
        reviewPriority: "high"
      })
    ).resolves.toMatchObject({
      confidenceStatus: "ready",
      locationScore: 1,
      oilScore: 0.9,
      reviewPriority: "high"
    });
    expect(query.updateCalls).toEqual([
      expect.objectContaining({
        confidence_provider: "mock",
        confidence_status: "ready",
        review_priority: "high"
      })
    ]);
  });

  it("persists failed confidence fields with neutral priority", async () => {
    const query = new FakeQuery({
      data: {
        ...submissionRow,
        confidence_provider: "vision-api",
        confidence_raw: { error: "provider down" },
        confidence_status: "failed"
      },
      error: null
    });
    const repository = createRepository(new FakeSupabaseClient([query]));

    await expect(
      repository.markFailed("submission-1", { error: "provider down" })
    ).resolves.toMatchObject({
      confidenceStatus: "failed",
      reviewPriority: "normal"
    });
    expect(query.updateCalls).toEqual([
      expect.objectContaining({
        confidence_provider: "vision-api",
        confidence_status: "failed",
        review_priority: "normal"
      })
    ]);
  });

  it("fails when a confidence update returns no row", async () => {
    const repository = createRepository(
      new FakeSupabaseClient([new FakeQuery({ data: null, error: null })])
    );

    await expect(
      repository.markFailed("missing", { error: "not found" })
    ).rejects.toMatchObject({
      code: "DISPOSAL_NOT_FOUND"
    });
  });
});
