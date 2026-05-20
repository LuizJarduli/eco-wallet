import { describe, expect, it } from "vitest";

import {
  buildAdminLoginRedirect,
  shouldProtectAdminPath,
  shouldRedirectToLogin
} from "@/features/admin-auth/services/admin-route-guard";

describe("admin route guard", () => {
  it("redirects unauthenticated visitors away from protected admin routes", () => {
    expect(shouldProtectAdminPath("/admin/verificacao")).toBe(true);
    expect(shouldRedirectToLogin(false, false)).toBe(true);
    expect(buildAdminLoginRedirect("http://localhost:3000/admin/verificacao")).toBe(
      "http://localhost:3000/admin/login"
    );
  });

  it("allows public admin login route", () => {
    expect(shouldProtectAdminPath("/admin/login")).toBe(false);
  });

  it("does not redirect authenticated admins", () => {
    expect(shouldRedirectToLogin(true, true)).toBe(false);
  });
});
