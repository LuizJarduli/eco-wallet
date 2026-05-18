import { AppError } from "../errors/app-error.js";
import { createSupabaseServiceClient } from "./service-client.js";

export type ProfileRole = "admin" | "member";

export type ProfileRoleLookup = (userId: string) => Promise<ProfileRole | null>;

export const getProfileRole: ProfileRoleLookup = async (userId) => {
  const { data, error } = await createSupabaseServiceClient()
    .from("profiles")
    .select("role")
    .eq("id", userId)
    .single<{ role: ProfileRole }>();

  if (error) {
    throw new AppError("FORBIDDEN", 403, "Admin access is required.");
  }

  return data?.role ?? null;
};
