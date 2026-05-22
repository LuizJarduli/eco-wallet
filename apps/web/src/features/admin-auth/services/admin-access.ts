import type { Session } from "@supabase/supabase-js";

export type AdminAccessResult =
  | { allowed: true; userId: string }
  | { allowed: false; reason: "unauthenticated" | "not_admin" };

export const isAdminRole = (role: string | null | undefined): boolean =>
  role === "admin";

export const resolveAdminAccess = (
  session: Session | null,
  role: string | null | undefined
): AdminAccessResult => {
  if (!session?.user.id) {
    return { allowed: false, reason: "unauthenticated" };
  }

  if (!isAdminRole(role)) {
    return { allowed: false, reason: "not_admin" };
  }

  return { allowed: true, userId: session.user.id };
};

export const resolveAdminAccessForUser = (
  userId: string | null | undefined,
  role: string | null | undefined
): AdminAccessResult => {
  if (!userId) {
    return { allowed: false, reason: "unauthenticated" };
  }

  if (!isAdminRole(role)) {
    return { allowed: false, reason: "not_admin" };
  }

  return { allowed: true, userId };
};

export const adminLoginPath = "/admin/login";
export const adminHomePath = "/admin/verificacao";
