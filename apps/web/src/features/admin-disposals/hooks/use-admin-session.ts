"use client";

import type { Session } from "@supabase/supabase-js";
import { useEffect, useState } from "react";

import { createSupabaseBrowserClient } from "@/core/lib/supabase";
import {
  adminLoginPath,
  resolveAdminAccess
} from "@/features/admin-auth/services/admin-access";

interface AdminSessionState {
  loading: boolean;
  accessToken: string | null;
  userId: string | null;
  deniedReason: "unauthenticated" | "not_admin" | null;
}

export const useAdminSession = (): AdminSessionState => {
  const [state, setState] = useState<AdminSessionState>({
    loading: true,
    accessToken: null,
    userId: null,
    deniedReason: null
  });

  useEffect(() => {
    const supabase = createSupabaseBrowserClient();

    const syncSession = async (session: Session | null) => {
      if (!session?.access_token) {
        setState({
          loading: false,
          accessToken: null,
          userId: null,
          deniedReason: "unauthenticated"
        });
        return;
      }

      const { data: profile } = await supabase
        .from("profiles")
        .select("role")
        .eq("id", session.user.id)
        .maybeSingle<{ role: string }>();

      const access = resolveAdminAccess(session, profile?.role);

      if (!access.allowed) {
        setState({
          loading: false,
          accessToken: null,
          userId: null,
          deniedReason: access.reason
        });
        return;
      }

      setState({
        loading: false,
        accessToken: session.access_token,
        userId: access.userId,
        deniedReason: null
      });
    };

    void supabase.auth.getSession().then(({ data }) => syncSession(data.session));

    const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
      void syncSession(session);
    });

    return () => {
      listener.subscription.unsubscribe();
    };
  }, []);

  return state;
};

export const redirectToAdminLogin = () => {
  if (typeof window !== "undefined") {
    window.location.assign(adminLoginPath);
  }
};
