import { createSupabasePublishableClient } from "./publishable-client.js";

export type SupabaseJwtVerifier = (token: string) => Promise<string | null>;

export const verifySupabaseJwt: SupabaseJwtVerifier = async (token) => {
  const {
    data: { user },
    error
  } = await createSupabasePublishableClient().auth.getUser(token);

  if (error || !user) {
    return null;
  }

  return user.id;
};
