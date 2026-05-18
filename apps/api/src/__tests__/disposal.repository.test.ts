import { describe, expect, it } from "vitest";

import type { SupabaseServiceClient } from "../core/supabase/service-client.js";
import { SupabaseDisposalRepository } from "../features/disposals/disposal.repository.js";

interface DbError {
  message: string;
}

interface DbResult<T> {
  data: T | null;
  error: DbError | null;
}

class FakeQuery<T> {
  readonly eqCalls: Array<[string, unknown]> = [];
  readonly inCalls: Array<[string, unknown[]]> = [];
  readonly orderCalls: Array<[string, unknown]> = [];

  constructor(private readonly result: DbResult<T>) {}

  select(_columns: string): this {
    return this;
  }

  eq(column: string, value: unknown): this {
    this.eqCalls.push([column, value]);
    return this;
  }

  in(column: string, values: unknown[]): this {
    this.inCalls.push([column, values]);
    return this;
  }

  update(_values: unknown): this {
    return this;
  }

  order(column: string, options: unknown): this {
    this.orderCalls.push([column, options]);
    return this;
  }

  limit(_count: number): this {
    return this;
  }

  async maybeSingle<U>(): Promise<DbResult<U>> {
    return this.result as unknown as DbResult<U>;
  }

  async single<U>(): Promise<DbResult<U>> {
    return this.result as unknown as DbResult<U>;
  }

  async returns<U>(): Promise<DbResult<U>> {
    return this.result as unknown as DbResult<U>;
  }
}

class FakeSupabaseClient {
  readonly fromCalls: string[] = [];
  readonly rpcCalls: Array<{ name: string; params: Record<string, unknown> }> = [];

  constructor(
    private readonly fromQueries: FakeQuery<unknown>[] = [],
    private readonly rpcQueries: FakeQuery<unknown>[] = []
  ) {}

  from(table: string): FakeQuery<unknown> {
    this.fromCalls.push(table);
    const query = this.fromQueries.shift();

    if (!query) {
      throw new Error(`Unexpected table query: ${table}`);
    }

    return query;
  }

  rpc(name: string, params: Record<string, unknown>): FakeQuery<unknown> {
    this.rpcCalls.push({ name, params });
    const query = this.rpcQueries.shift();

    if (!query) {
      throw new Error(`Unexpected rpc query: ${name}`);
    }

    return query;
  }
}

const createRepository = (client: FakeSupabaseClient) =>
  new SupabaseDisposalRepository(client as unknown as SupabaseServiceClient);

describe("SupabaseDisposalRepository", () => {
  it("maps submission rows from Supabase", async () => {
    const query = new FakeQuery({
      data: {
        confidence_status: "ready",
        estimated_liters: "2.50",
        id: "submission-1",
        location_score: "0.700",
        oil_score: "0.900",
        rejection_reason: null,
        review_priority: "high",
        status: "submitted",
        submitted_at: "2026-05-17T20:00:00.000Z",
        updated_at: "2026-05-17T21:00:00.000Z",
        user_id: "member-1"
      },
      error: null
    });
    const client = new FakeSupabaseClient([query]);
    const repository = createRepository(client);

    await expect(repository.findSubmission("submission-1")).resolves.toMatchObject({
      estimatedLiters: 2.5,
      id: "submission-1",
      locationScore: 0.7,
      oilScore: 0.9,
      reviewPriority: "high",
      status: "submitted",
      userId: "member-1"
    });
    expect(query.eqCalls).toEqual([["id", "submission-1"]]);
  });

  it("maps numeric submission values without conversion loss", async () => {
    const repository = createRepository(
      new FakeSupabaseClient([
        new FakeQuery({
          data: {
            confidence_status: "ready",
            estimated_liters: 2,
            id: "submission-1",
            location_score: 0.7,
            oil_score: 0.9,
            rejection_reason: null,
            review_priority: "normal",
            status: "submitted",
            submitted_at: "2026-05-17T20:00:00.000Z",
            updated_at: "2026-05-17T21:00:00.000Z",
            user_id: "member-1"
          },
          error: null
        })
      ])
    );

    await expect(repository.findSubmission("submission-1")).resolves.toMatchObject({
      estimatedLiters: 2,
      locationScore: 0.7,
      oilScore: 0.9
    });
  });

  it("maps missing submission errors", async () => {
    const repository = createRepository(
      new FakeSupabaseClient([
        new FakeQuery({
          data: null,
          error: { message: "DISPOSAL_NOT_FOUND" }
        })
      ])
    );

    await expect(repository.findSubmission("missing")).rejects.toMatchObject({
      code: "DISPOSAL_NOT_FOUND"
    });
  });

  it("returns null when a submission row is absent", async () => {
    const repository = createRepository(
      new FakeSupabaseClient([new FakeQuery({ data: null, error: null })])
    );

    await expect(repository.findSubmission("missing")).resolves.toBeNull();
  });

  it("maps active reward rules", async () => {
    const repository = createRepository(
      new FakeSupabaseClient([
        new FakeQuery({
          data: {
            coins_per_liter: 10,
            id: "rule-1",
            min_liters: "1.00"
          },
          error: null
        })
      ])
    );

    await expect(repository.getActiveRewardRule()).resolves.toEqual({
      coinsPerLiter: 10,
      id: "rule-1",
      minLiters: 1
    });
  });

  it("fails when no active reward rule is available", async () => {
    const repository = createRepository(
      new FakeSupabaseClient([
        new FakeQuery({
          data: null,
          error: { message: "No rows" }
        })
      ])
    );

    await expect(repository.getActiveRewardRule()).rejects.toMatchObject({
      code: "INTERNAL_ERROR"
    });
  });

  it("maps approve RPC results", async () => {
    const client = new FakeSupabaseClient(
      [],
      [new FakeQuery({ data: { pending_coins: 20 }, error: null })]
    );
    const repository = createRepository(client);

    await expect(
      repository.approveSubmission({
        adminId: "admin-1",
        estimatedLiters: 2,
        submissionId: "submission-1"
      })
    ).resolves.toEqual({ pendingCoins: 20 });
    expect(client.rpcCalls).toEqual([
      {
        name: "approve_disposal_admin",
        params: {
          p_admin_id: "admin-1",
          p_estimated_liters: 2,
          p_submission_id: "submission-1"
        }
      }
    ]);
  });

  it("maps audit RPC results", async () => {
    const repository = createRepository(
      new FakeSupabaseClient(
        [],
        [new FakeQuery({ data: { coins_released: 20 }, error: null })]
      )
    );

    await expect(
      repository.auditCollection({
        adminId: "admin-1",
        auditedLiters: 2,
        submissionId: "submission-1"
      })
    ).resolves.toEqual({ coinsReleased: 20 });
  });

  it("maps domain RPC errors", async () => {
    const repository = createRepository(
      new FakeSupabaseClient(
        [],
        [new FakeQuery({ data: null, error: { message: "BELOW_MIN_VOLUME" } })]
      )
    );

    await expect(
      repository.auditCollection({
        adminId: "admin-1",
        auditedLiters: 0.5,
        submissionId: "submission-1"
      })
    ).rejects.toMatchObject({
      code: "BELOW_MIN_VOLUME"
    });
  });

  it("maps invalid transition RPC errors", async () => {
    const repository = createRepository(
      new FakeSupabaseClient(
        [],
        [new FakeQuery({ data: null, error: { message: "INVALID_TRANSITION" } })]
      )
    );

    await expect(
      repository.approveSubmission({
        adminId: "admin-1",
        estimatedLiters: 2,
        submissionId: "submission-1"
      })
    ).rejects.toMatchObject({
      code: "INVALID_TRANSITION"
    });
  });

  it("maps unknown persistence errors", async () => {
    const repository = createRepository(
      new FakeSupabaseClient(
        [],
        [new FakeQuery({ data: null, error: { message: "database offline" } })]
      )
    );

    await expect(
      repository.auditCollection({
        adminId: "admin-1",
        auditedLiters: 2,
        submissionId: "submission-1"
      })
    ).rejects.toMatchObject({
      code: "INTERNAL_ERROR"
    });
  });

  it("fails when approve RPC returns no row", async () => {
    const repository = createRepository(
      new FakeSupabaseClient(
        [],
        [new FakeQuery({ data: null, error: null })]
      )
    );

    await expect(
      repository.approveSubmission({
        adminId: "admin-1",
        estimatedLiters: 2,
        submissionId: "submission-1"
      })
    ).rejects.toMatchObject({
      code: "INTERNAL_ERROR"
    });
  });

  it("fails when audit RPC returns no row", async () => {
    const repository = createRepository(
      new FakeSupabaseClient(
        [],
        [new FakeQuery({ data: null, error: null })]
      )
    );

    await expect(
      repository.auditCollection({
        adminId: "admin-1",
        auditedLiters: 2,
        submissionId: "submission-1"
      })
    ).rejects.toMatchObject({
      code: "INTERNAL_ERROR"
    });
  });

  it("updates rejected submissions with allowed source statuses", async () => {
    const query = new FakeQuery({ data: null, error: null });
    const repository = createRepository(new FakeSupabaseClient([query]));

    await expect(
      repository.rejectSubmission({
        adminId: "admin-1",
        reasonCode: "not_oil",
        submissionId: "submission-1"
      })
    ).resolves.toBeUndefined();
    expect(query.eqCalls).toEqual([["id", "submission-1"]]);
    expect(query.inCalls).toEqual([
      ["status", ["submitted", "under_review"]]
    ]);
  });

  it("applies status and priority filters to admin listing", async () => {
    const query = new FakeQuery({
      data: [
        {
          confidence_status: "pending",
          estimated_liters: null,
          id: "submission-1",
          location_score: null,
          oil_score: null,
          rejection_reason: null,
          review_priority: "high",
          status: "awaiting_audit",
          submitted_at: "2026-05-17T20:00:00.000Z",
          updated_at: "2026-05-17T20:00:00.000Z",
          user_id: "member-1"
        }
      ],
      error: null
    });
    const repository = createRepository(new FakeSupabaseClient([query]));

    await expect(
      repository.listAdminDisposals({
        priority: "high",
        status: "awaiting_audit"
      })
    ).resolves.toHaveLength(1);
    expect(query.eqCalls).toEqual([
      ["status", "awaiting_audit"],
      ["review_priority", "high"]
    ]);
  });

  it("returns an empty admin list when Supabase returns null data", async () => {
    const query = new FakeQuery({ data: null, error: null });
    const repository = createRepository(new FakeSupabaseClient([query]));

    await expect(repository.listAdminDisposals({})).resolves.toEqual([]);
    expect(query.eqCalls).toEqual([]);
  });
});
