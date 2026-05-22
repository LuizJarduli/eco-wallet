const requirePublic = (value: string | undefined, name: string): string => {
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
};

// Use static process.env.* keys so Next can inline them in client bundles.
// Dynamic process.env[name] is empty in the browser.
const publicSupabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publicSupabasePublishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const publicApiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL;

export const publicEnv = {
  supabaseUrl: () => requirePublic(publicSupabaseUrl, "NEXT_PUBLIC_SUPABASE_URL"),
  supabasePublishableKey: () =>
    requirePublic(
      publicSupabasePublishableKey,
      "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY"
    ),
  apiBaseUrl: () => publicApiBaseUrl?.replace(/\/$/, "") ?? "http://localhost:4000"
};

export const serverEnv = {
  supabaseServiceRoleKey: () =>
    process.env.SUPABASE_SERVICE_ROLE_KEY ??
    process.env.SUPABASE_SERVICE_KEY ??
    ""
};
