import type { NextFunction, Request, Response } from "express";
import { describe, expect, it, vi } from "vitest";

import { AppError } from "../core/errors/app-error.js";
import { authenticateJwt } from "../core/middleware/auth.js";
import { createJwtVerifier } from "../test/fakes.js";

const createRequest = (authorization?: string): Request =>
  ({
    header: vi.fn((name: string) =>
      name.toLowerCase() === "authorization" ? authorization : undefined
    )
  }) as unknown as Request;

const response = {} as Response;

describe("authenticateJwt", () => {
  it("sets req.userId and calls next for a valid Supabase JWT", async () => {
    const request = createRequest("Bearer valid-token");
    const next = vi.fn();

    await authenticateJwt(createJwtVerifier("user-123"))(
      request,
      response,
      next as unknown as NextFunction
    );

    expect(request.userId).toBe("user-123");
    expect(next).toHaveBeenCalledOnce();
    expect(next).toHaveBeenCalledWith();
  });

  it("returns UNAUTHORIZED when Authorization header is missing", async () => {
    const request = createRequest();
    const next = vi.fn();

    await authenticateJwt(createJwtVerifier("user-123"))(
      request,
      response,
      next as unknown as NextFunction
    );

    const error = next.mock.calls[0]?.[0];
    expect(error).toBeInstanceOf(AppError);
    expect(error).toMatchObject({ code: "UNAUTHORIZED", statusCode: 401 });
  });

  it("returns UNAUTHORIZED for an expired Supabase JWT", async () => {
    const request = createRequest("Bearer expired-token");
    const next = vi.fn();

    await authenticateJwt(createJwtVerifier(null))(
      request,
      response,
      next as unknown as NextFunction
    );

    const error = next.mock.calls[0]?.[0];
    expect(error).toBeInstanceOf(AppError);
    expect(error).toMatchObject({ code: "UNAUTHORIZED", statusCode: 401 });
  });
});
