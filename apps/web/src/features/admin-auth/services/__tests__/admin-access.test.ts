import { describe, expect, it } from "vitest";

import {
  adminLoginPath,
  resolveAdminAccess,
  resolveAdminAccessForUser
} from "@/features/admin-auth/services/admin-access";

describe("admin access", () => {
  it("denies unauthenticated visitors", () => {
    expect(resolveAdminAccess(null, "admin")).toEqual({
      allowed: false,
      reason: "unauthenticated"
    });
    expect(resolveAdminAccessForUser(null, "admin")).toEqual({
      allowed: false,
      reason: "unauthenticated"
    });
  });

  it("denies authenticated non-admin users", () => {
    const session = {
      access_token: "token",
      user: { id: "user-1" }
    } as never;

    expect(resolveAdminAccess(session, "member")).toEqual({
      allowed: false,
      reason: "not_admin"
    });
  });

  it("allows admin users", () => {
    const session = {
      access_token: "token",
      user: { id: "admin-1" }
    } as never;

    expect(resolveAdminAccess(session, "admin")).toEqual({
      allowed: true,
      userId: "admin-1"
    });
  });

  it("uses admin login path for redirects", () => {
    expect(adminLoginPath).toBe("/admin/login");
  });

  it("denies empty user id", () => {
    expect(resolveAdminAccessForUser("", "admin")).toEqual({
      allowed: false,
      reason: "unauthenticated"
    });
  });

  it("allows admin user id without session object", () => {
    expect(resolveAdminAccessForUser("admin-1", "admin")).toEqual({
      allowed: true,
      userId: "admin-1"
    });
  });
});
