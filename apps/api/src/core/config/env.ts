export interface SupabaseEnv {
  supabaseUrl: string;
  supabaseServiceRoleKey: string;
}

const readRequiredEnv = (
  env: NodeJS.ProcessEnv,
  key: keyof NodeJS.ProcessEnv
): string => {
  const value = env[key];

  if (!value) {
    throw new Error(`Missing required environment variable: ${String(key)}`);
  }

  return value;
};

export const readSupabaseEnv = (
  env: NodeJS.ProcessEnv = process.env
): SupabaseEnv => ({
  supabaseUrl: readRequiredEnv(env, "SUPABASE_URL"),
  supabaseServiceRoleKey: readRequiredEnv(env, "SUPABASE_SERVICE_ROLE_KEY")
});
