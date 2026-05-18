import type { NextFunction, Request, Response } from "express";
import { describe, expect, it, vi } from "vitest";

import { AppError } from "../core/errors/app-error.js";
import { requireAdmin } from "../core/middleware/require-admin.js";
import { createRoleLookup } from "../test/fakes.js";

const createRequest = (userId?: string): Request =>
  ({
    userId
  }) as Request;

const response = {} as Response;

describe("requireAdmin", () => {
  it("calls next for admins", async () => {
    const request = createRequest("admin-123");
    const next = vi.fn();

    await requireAdmin(createRoleLookup("admin"))(
      request,
      response,
      next as unknown as NextFunction
    );

    expect(next).toHaveBeenCalledOnce();
    expect(next).toHaveBeenCalledWith();
  });

  it("returns FORBIDDEN for members", async () => {
    const request = createRequest("member-123");
    const next = vi.fn();

    await requireAdmin(createRoleLookup("member"))(
      request,
      response,
      next as unknown as NextFunction
    );

    const error = next.mock.calls[0]?.[0];
    expect(error).toBeInstanceOf(AppError);
    expect(error).toMatchObject({ code: "FORBIDDEN", statusCode: 403 });
  });

  it("returns UNAUTHORIZED when authentication context is missing", async () => {
    const request = createRequest();
    const next = vi.fn();

    await requireAdmin(createRoleLookup("admin"))(
      request,
      response,
      next as unknown as NextFunction
    );

    const error = next.mock.calls[0]?.[0];
    expect(error).toBeInstanceOf(AppError);
    expect(error).toMatchObject({ code: "UNAUTHORIZED", statusCode: 401 });
  });
});
