import type { ConfidenceInput, ConfidenceResult } from "@eco-wallet/domain";
import request from "supertest";
import { describe, expect, it, vi } from "vitest";

import { createApp } from "../core/http/app.js";
import {
  calculateLocationScore,
  createConfidenceService
} from "../features/confidence/confidence.service.js";
import type {
  ConfidenceRepository,
  ConfidenceScorer,
  ConfidenceSubmission,
  DropOffPoint
} from "../features/confidence/confidence.types.js";
import {
  HttpVisionProvider,
  VisionConfidenceScorer
} from "../features/confidence/vision-confidence.scorer.js";
import { createJwtVerifier, createRoleLookup } from "../test/fakes.js";

const createSubmission = (
  overrides: Partial<ConfidenceSubmission> = {}
): ConfidenceSubmission => ({
  captureLat: -23.501,
  captureLng: -47.46,
  confidenceStatus: "pending",
  dropOffId: "drop-off-1",
  id: "submission-1",
  locationScore: null,
  oilScore: null,
  provider: null,
  raw: null,
  reviewPriority: "normal",
  storagePath: "member-1/photo.jpg",
  submittedAt: "2026-05-17T20:00:00.000Z",
  userId: "member-1",
  ...overrides
});

const createDropOffPoint = (
  overrides: Partial<DropOffPoint> = {}
): DropOffPoint => ({
  active: true,
  id: "drop-off-1",
  latitude: -23.501,
  longitude: -47.46,
  ...overrides
});

class InMemoryConfidenceRepository implements ConfidenceRepository {
  readonly signedUrlRequests: string[] = [];
  readonly readyUpdates: ConfidenceResult[] = [];
  readonly failedUpdates: Record<string, unknown>[] = [];

  constructor(
    private readonly submissions: ConfidenceSubmission[],
    private readonly dropOffs: DropOffPoint[] = [createDropOffPoint()]
  ) {}

  async createSignedImageUrl(storagePath: string): Promise<string> {
    this.signedUrlRequests.push(storagePath);
    return `https://storage.test/${storagePath}`;
  }

  async findSubmission(
    submissionId: string
  ): Promise<ConfidenceSubmission | null> {
    return this.submissions.find((submission) => submission.id === submissionId) ?? null;
  }

  async findDropOffPoint(dropOffId: string): Promise<DropOffPoint | null> {
    return this.dropOffs.find((dropOff) => dropOff.id === dropOffId) ?? null;
  }

  async findRecentDuplicate(input: {
    excludeSubmissionId: string;
    storagePath: string;
    submittedAfter: string;
    userId: string;
  }) {
    return (
      this.submissions.find(
        (submission) =>
          submission.id !== input.excludeSubmissionId &&
          submission.userId === input.userId &&
          submission.storagePath === input.storagePath &&
          submission.submittedAt >= input.submittedAfter
      ) ?? null
    );
  }

  async markReady(
    submissionId: string,
    result: ConfidenceResult
  ): Promise<ConfidenceSubmission> {
    const submission = await this.findSubmission(submissionId);

    if (!submission) {
      throw new Error("missing submission");
    }

    this.readyUpdates.push(result);
    submission.confidenceStatus = "ready";
    submission.locationScore = result.locationScore;
    submission.oilScore = result.oilScore;
    submission.provider = result.provider;
    submission.raw = result.raw ?? null;
    submission.reviewPriority = result.reviewPriority;

    return submission;
  }

  async markFailed(
    submissionId: string,
    metadata: Record<string, unknown>
  ): Promise<ConfidenceSubmission> {
    const submission = await this.findSubmission(submissionId);

    if (!submission) {
      throw new Error("missing submission");
    }

    this.failedUpdates.push(metadata);
    submission.confidenceStatus = "failed";
    submission.locationScore = null;
    submission.oilScore = null;
    submission.provider = "vision-api";
    submission.raw = metadata;
    submission.reviewPriority = "normal";

    return submission;
  }
}

class MockScorer implements ConfidenceScorer {
  readonly inputs: ConfidenceInput[] = [];

  constructor(private readonly result: ConfidenceResult | Error) {}

  async score(input: ConfidenceInput): Promise<ConfidenceResult> {
    this.inputs.push(input);

    if (this.result instanceof Error) {
      throw this.result;
    }

    return this.result;
  }
}

const retryWithoutDelay = {
  delay: async () => undefined,
  initialBackoffMs: 1,
  maxAttempts: 3
};

describe("ConfidenceService", () => {
  it("scores a pending submission and marks high-confidence results as ready", async () => {
    const repository = new InMemoryConfidenceRepository([createSubmission()]);
    const scorer = new MockScorer({
      locationScore: 1,
      oilScore: 0.9,
      provider: "mock-vision",
      raw: { label: "used-oil" },
      reviewPriority: "normal"
    });
    const service = createConfidenceService(repository, scorer, retryWithoutDelay);

    const result = await service.scoreSubmission("submission-1", "member-1");

    expect(result.idempotent).toBe(false);
    expect(result.submission).toMatchObject({
      confidenceStatus: "ready",
      locationScore: 1,
      oilScore: 0.9,
      provider: "mock-vision",
      reviewPriority: "high"
    });
    expect(repository.signedUrlRequests).toEqual(["member-1/photo.jpg"]);
    expect(scorer.inputs).toHaveLength(1);
    expect(repository.readyUpdates[0]?.raw).toMatchObject({
      duplicateDetected: false,
      label: "used-oil"
    });
  });

  it("sets failed confidence with normal priority after vision retries fail", async () => {
    const repository = new InMemoryConfidenceRepository([createSubmission()]);
    const scorer = new MockScorer(new Error("provider down"));
    const service = createConfidenceService(repository, scorer, retryWithoutDelay);

    const result = await service.scoreSubmission("submission-1", "member-1");

    expect(result.submission).toMatchObject({
      confidenceStatus: "failed",
      reviewPriority: "normal"
    });
    expect(scorer.inputs).toHaveLength(3);
    expect(repository.failedUpdates).toEqual([
      { attempts: 3, error: "provider down" }
    ]);
  });

  it("lowers the location score when capture coordinates are around 500m away", () => {
    const score = calculateLocationScore(
      createSubmission({ captureLat: 0, captureLng: 0.0045 }),
      createDropOffPoint({ latitude: 0, longitude: 0 })
    );

    expect(score).toBeGreaterThan(0.4);
    expect(score).toBeLessThan(0.7);
  });

  it("returns zero location score when coordinates or active drop-off are missing", () => {
    expect(
      calculateLocationScore(createSubmission({ captureLat: null }), createDropOffPoint())
    ).toBe(0);
    expect(
      calculateLocationScore(
        createSubmission(),
        createDropOffPoint({ active: false })
      )
    ).toBe(0);
  });

  it("returns zero location score when capture coordinates are too far away", () => {
    const score = calculateLocationScore(
      createSubmission({ captureLat: 0, captureLng: 0.02 }),
      createDropOffPoint({ latitude: 0, longitude: 0 })
    );

    expect(score).toBe(0);
  });

  it("keeps duplicate submissions neutral even when vision confidence is high", async () => {
    const repository = new InMemoryConfidenceRepository([
      createSubmission({
        id: "submission-0",
        submittedAt: "2026-05-17T19:55:00.000Z"
      }),
      createSubmission()
    ]);
    const scorer = new MockScorer({
      locationScore: 1,
      oilScore: 0.9,
      provider: "mock-vision",
      reviewPriority: "high"
    });
    const service = createConfidenceService(repository, scorer, retryWithoutDelay);

    const result = await service.scoreSubmission("submission-1", "member-1");

    expect(result.submission.reviewPriority).toBe("normal");
    expect(result.submission.raw).toMatchObject({
      duplicateDetected: true,
      duplicateSubmissionId: "submission-0"
    });
  });

  it("marks low-confidence or poor-location submissions as low priority", async () => {
    const repository = new InMemoryConfidenceRepository([
      createSubmission({ captureLat: 0, captureLng: 0.02 })
    ], [createDropOffPoint({ latitude: 0, longitude: 0 })]);
    const scorer = new MockScorer({
      locationScore: 1,
      oilScore: 0.4,
      provider: "mock-vision",
      reviewPriority: "normal"
    });
    const service = createConfidenceService(repository, scorer, retryWithoutDelay);

    const result = await service.scoreSubmission("submission-1", "member-1");

    expect(result.submission).toMatchObject({
      locationScore: 0,
      reviewPriority: "low"
    });
  });

  it("does not call the scorer again when confidence is already ready", async () => {
    const repository = new InMemoryConfidenceRepository([
      createSubmission({
        confidenceStatus: "ready",
        locationScore: 1,
        oilScore: 0.9,
        provider: "mock-vision",
        reviewPriority: "high"
      })
    ]);
    const scorer = new MockScorer(new Error("should not be called"));
    const service = createConfidenceService(repository, scorer, retryWithoutDelay);

    const result = await service.scoreSubmission("submission-1", "member-1");

    expect(result.idempotent).toBe(true);
    expect(scorer.inputs).toHaveLength(0);
    expect(repository.signedUrlRequests).toHaveLength(0);
  });

  it("returns FORBIDDEN when a member scores another user's submission", async () => {
    const repository = new InMemoryConfidenceRepository([createSubmission()]);
    const scorer = new MockScorer(new Error("should not be called"));
    const service = createConfidenceService(repository, scorer, retryWithoutDelay);

    await expect(service.scoreSubmission("submission-1", "member-2")).rejects.toMatchObject({
      code: "FORBIDDEN"
    });
    expect(scorer.inputs).toHaveLength(0);
  });
});

describe("confidence API", () => {
  it("POST /v1/disposals/:id/score updates a pending submission to ready", async () => {
    const repository = new InMemoryConfidenceRepository([createSubmission()]);
    const scorer = new MockScorer({
      locationScore: 1,
      oilScore: 0.9,
      provider: "mock-vision",
      reviewPriority: "normal"
    });

    const response = await request(
      createApp({
        confidenceRepository: repository,
        confidenceRetryOptions: retryWithoutDelay,
        confidenceScorer: scorer,
        jwtVerifier: createJwtVerifier("member-1"),
        profileRoleLookup: createRoleLookup("member")
      })
    )
      .post("/v1/disposals/submission-1/score")
      .set("Authorization", "Bearer valid-token")
      .expect(200);

    expect(response.body).toMatchObject({
      data: {
        confidenceStatus: "ready",
        id: "submission-1",
        idempotent: false,
        oilScore: 0.9,
        reviewPriority: "high"
      }
    });
    await expect(repository.findSubmission("submission-1")).resolves.toMatchObject({
      confidenceStatus: "ready"
    });
  });

  it("returns FORBIDDEN when a member cannot score another user's submission", async () => {
    const repository = new InMemoryConfidenceRepository([createSubmission()]);
    const scorer = new MockScorer(new Error("should not be called"));

    const response = await request(
      createApp({
        confidenceRepository: repository,
        confidenceRetryOptions: retryWithoutDelay,
        confidenceScorer: scorer,
        jwtVerifier: createJwtVerifier("member-2"),
        profileRoleLookup: createRoleLookup("member")
      })
    )
      .post("/v1/disposals/submission-1/score")
      .set("Authorization", "Bearer valid-token")
      .expect(403);

    expect(response.body.error.code).toBe("FORBIDDEN");
    expect(scorer.inputs).toHaveLength(0);
  });

  it("requires a member role", async () => {
    const response = await request(
      createApp({
        confidenceRepository: new InMemoryConfidenceRepository([createSubmission()]),
        jwtVerifier: createJwtVerifier("admin-1"),
        profileRoleLookup: createRoleLookup("admin")
      })
    )
      .post("/v1/disposals/submission-1/score")
      .set("Authorization", "Bearer valid-token")
      .expect(403);

    expect(response.body.error.message).toBe("Member access is required.");
  });
});

describe("HttpVisionProvider", () => {
  it("maps provider scores from the configured server-side endpoint", async () => {
    const fetcher = vi.fn(async () => {
      return new Response(JSON.stringify({ oilScore: 1.2, vendor: "mock" }), {
        status: 200
      });
    });
    const provider = new HttpVisionProvider(
      { apiKey: "secret-key", endpoint: "https://vision.test/score" },
      fetcher as unknown as typeof fetch
    );

    await expect(
      provider.analyzeOilLikelihood("https://storage.test/photo.jpg")
    ).resolves.toEqual({
      oilScore: 1,
      raw: { oilScore: 1.2, vendor: "mock" }
    });
    expect(fetcher).toHaveBeenCalledWith(
      "https://vision.test/score",
      expect.objectContaining({
        headers: expect.objectContaining({
          authorization: "Bearer secret-key"
        })
      })
    );
  });

  it("also accepts provider payloads that use a generic score field", async () => {
    const provider = new HttpVisionProvider(
      { apiKey: "secret-key", endpoint: "https://vision.test/score" },
      (async () =>
        new Response(JSON.stringify({ score: 0.25 }), {
          status: 200
        })) as typeof fetch
    );

    await expect(provider.analyzeOilLikelihood("image-url")).resolves.toMatchObject({
      oilScore: 0.25
    });
  });

  it("fails when the provider response is not successful", async () => {
    const provider = new HttpVisionProvider(
      { apiKey: "secret-key", endpoint: "https://vision.test/score" },
      (async () => new Response("nope", { status: 500 })) as typeof fetch
    );

    await expect(provider.analyzeOilLikelihood("image-url")).rejects.toMatchObject({
      code: "INTERNAL_ERROR"
    });
  });

  it("fails when the provider score is missing", async () => {
    const provider = new HttpVisionProvider(
      { apiKey: "secret-key", endpoint: "https://vision.test/score" },
      (async () =>
        new Response(JSON.stringify({ label: "oil" }), {
          status: 200
        })) as typeof fetch
    );

    await expect(provider.analyzeOilLikelihood("image-url")).rejects.toMatchObject({
      code: "INTERNAL_ERROR"
    });
  });

  it("requires server-side vision provider environment by default", () => {
    const originalUrl = process.env.VISION_API_URL;
    const originalKey = process.env.VISION_API_KEY;
    delete process.env.VISION_API_URL;
    delete process.env.VISION_API_KEY;

    expect(() => new HttpVisionProvider()).toThrow(
      "Missing required vision provider environment variables."
    );

    if (originalUrl === undefined) {
      delete process.env.VISION_API_URL;
    } else {
      process.env.VISION_API_URL = originalUrl;
    }

    if (originalKey === undefined) {
      delete process.env.VISION_API_KEY;
    } else {
      process.env.VISION_API_KEY = originalKey;
    }
  });
});

describe("VisionConfidenceScorer", () => {
  it("wraps a vision provider in the shared ConfidenceScorer contract", async () => {
    const scorer = new VisionConfidenceScorer(
      {
        analyzeOilLikelihood: async () => ({
          oilScore: 0.7,
          raw: { label: "maybe-oil" }
        })
      },
      "mock-provider"
    );

    await expect(
      scorer.score({
        captureLat: 0,
        captureLng: 0,
        dropOffId: "drop-off-1",
        imageUrl: "image-url",
        submissionId: "submission-1"
      })
    ).resolves.toEqual({
      locationScore: 1,
      oilScore: 0.7,
      provider: "mock-provider",
      raw: { label: "maybe-oil" },
      reviewPriority: "normal"
    });
  });
});
