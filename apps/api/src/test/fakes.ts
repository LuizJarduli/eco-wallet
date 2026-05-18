import type { SupabaseJwtVerifier } from "../core/supabase/auth-user.service.js";
import type { ProfileRole } from "../core/supabase/profile-role.service.js";

export const createJwtVerifier =
  (userId: string | null): SupabaseJwtVerifier =>
  async () =>
    userId;

export const createRoleLookup = (role: ProfileRole | null) => async () => role;
