import { createClient, type SupabaseClient } from "@supabase/supabase-js";

import { readSupabaseEnv, type SupabaseEnv } from "../config/env.js";

export type SupabasePublishableClient = SupabaseClient;

export const createSupabasePublishableClient = (
  config: SupabaseEnv = readSupabaseEnv()
): SupabasePublishableClient =>
  createClient(config.supabaseUrl, config.supabasePublishableKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  });
