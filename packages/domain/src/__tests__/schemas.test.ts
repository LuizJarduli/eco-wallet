import { describe, expect, it } from "vitest";

import {
  approveDisposalBodySchema,
  createAuditDisposalBodySchema,
  rejectDisposalBodySchema,
  scratchPlayBodySchema
} from "../index.js";

describe("admin disposal schemas", () => {
  it("rejects negative approve estimatedLiters", () => {
    const result = approveDisposalBodySchema.safeParse({
      estimatedLiters: -1
    });

    expect(result.success).toBe(false);
  });

  it("accepts positive approve estimatedLiters", () => {
    const result = approveDisposalBodySchema.safeParse({
      estimatedLiters: 1.25
    });

    expect(result.success).toBe(true);
  });

  it("requires reject reasonCode to be a valid enum value", () => {
    const result = rejectDisposalBodySchema.safeParse({
      reasonCode: "not_a_reason"
    });

    expect(result.success).toBe(false);
  });

  it("accepts a known rejection reasonCode and optional note", () => {
    const result = rejectDisposalBodySchema.safeParse({
      reasonCode: "unclear_photo",
      note: "Photo is too dark."
    });

    expect(result.success).toBe(true);
  });

  it("rejects auditedLiters below the active min_liters service contract", () => {
    const activeRuleSchema = createAuditDisposalBodySchema(1);

    const result = activeRuleSchema.safeParse({
      auditedLiters: 0.75
    });

    expect(result.success).toBe(false);
  });

  it("accepts auditedLiters equal to the active min_liters service contract", () => {
    const activeRuleSchema = createAuditDisposalBodySchema(1);

    const result = activeRuleSchema.safeParse({
      auditedLiters: 1
    });

    expect(result.success).toBe(true);
  });
});

describe("scratch play schema", () => {
  it("rejects missing campaignId", () => {
    const result = scratchPlayBodySchema.safeParse({});

    expect(result.success).toBe(false);
  });

  it("accepts a campaignId UUID", () => {
    const result = scratchPlayBodySchema.safeParse({
      campaignId: "3f767c9d-f95f-49f3-8945-57b74d9a2f75"
    });

    expect(result.success).toBe(true);
  });
});
