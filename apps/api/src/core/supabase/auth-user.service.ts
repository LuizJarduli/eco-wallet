import { createSupabaseServiceClient } from "./service-client.js";

export type SupabaseJwtVerifier = (token: string) => Promise<string | null>;

export const verifySupabaseJwt: SupabaseJwtVerifier = async (token) => {
  const {
    data: { user },
    error
  } = await createSupabaseServiceClient().auth.getUser(token);

  if (error || !user) {
    return null;
  }

  return user.id;
};
