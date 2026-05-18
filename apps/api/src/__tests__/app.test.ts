import request from "supertest";
import { describe, expect, it } from "vitest";

import { createApp } from "../core/http/app.js";
import { createJwtVerifier, createRoleLookup } from "../test/fakes.js";

describe("API app", () => {
  it("keeps GET /health available", async () => {
    const response = await request(createApp()).get("/health").expect(200);

    expect(response.body).toMatchObject({ status: "ok" });
  });

  it("returns UNAUTHORIZED on protected routes without Authorization header", async () => {
    const response = await request(
      createApp({
        jwtVerifier: createJwtVerifier("member-123"),
        profileRoleLookup: createRoleLookup("admin")
      })
    )
      .get("/v1/admin/protected-stub")
      .expect(401);

    expect(response.body).toEqual({
      error: {
        code: "UNAUTHORIZED",
        message: "Missing Authorization header."
      }
    });
  });

  it("returns UNAUTHORIZED on protected routes for invalid JWTs", async () => {
    const response = await request(
      createApp({
        jwtVerifier: createJwtVerifier(null),
        profileRoleLookup: createRoleLookup("admin")
      })
    )
      .get("/v1/admin/protected-stub")
      .set("Authorization", "Bearer invalid-token")
      .expect(401);

    expect(response.body.error.code).toBe("UNAUTHORIZED");
  });

  it("returns FORBIDDEN when a member JWT reaches an admin route", async () => {
    const response = await request(
      createApp({
        jwtVerifier: createJwtVerifier("member-123"),
        profileRoleLookup: createRoleLookup("member")
      })
    )
      .get("/v1/admin/protected-stub")
      .set("Authorization", "Bearer valid-token")
      .expect(403);

    expect(response.body).toEqual({
      error: {
        code: "FORBIDDEN",
        message: "Admin access is required."
      }
    });
  });

  it("allows admins through the protected route stub", async () => {
    const response = await request(
      createApp({
        jwtVerifier: createJwtVerifier("admin-123"),
        profileRoleLookup: createRoleLookup("admin")
      })
    )
      .get("/v1/admin/protected-stub")
      .set("Authorization", "Bearer valid-token")
      .expect(200);

    expect(response.body).toEqual({ ok: true, userId: "admin-123" });
  });

  it("returns structured NOT_FOUND errors", async () => {
    const response = await request(createApp()).get("/missing").expect(404);

    expect(response.body).toEqual({
      error: {
        code: "NOT_FOUND",
        message: "Route not found."
      }
    });
  });
});
