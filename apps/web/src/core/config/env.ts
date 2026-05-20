const requiredPublic = (name: string): string => {
  const value = process.env[name];

  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
};

export const publicEnv = {
  supabaseUrl: () => requiredPublic("NEXT_PUBLIC_SUPABASE_URL"),
  supabaseAnonKey: () => requiredPublic("NEXT_PUBLIC_SUPABASE_ANON_KEY"),
  apiBaseUrl: () =>
    process.env.NEXT_PUBLIC_API_BASE_URL?.replace(/\/$/, "") ?? "http://localhost:4000"
};

export const serverEnv = {
  supabaseServiceRoleKey: () =>
    process.env.SUPABASE_SERVICE_ROLE_KEY ??
    process.env.SUPABASE_SERVICE_KEY ??
    ""
};
