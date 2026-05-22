import { createBrowserClient } from "@supabase/ssr";

import { publicEnv } from "@/core/config/env";

export const createSupabaseBrowserClient = () =>
  createBrowserClient(publicEnv.supabaseUrl(), publicEnv.supabasePublishableKey());
