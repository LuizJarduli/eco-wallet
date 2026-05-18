import { createClient, type SupabaseClient } from "@supabase/supabase-js";

import { readSupabaseEnv, type SupabaseEnv } from "../config/env.js";

export type SupabaseServiceClient = SupabaseClient;

export const createSupabaseServiceClient = (
  config: SupabaseEnv = readSupabaseEnv()
): SupabaseServiceClient =>
  createClient(config.supabaseUrl, config.supabaseServiceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  });
