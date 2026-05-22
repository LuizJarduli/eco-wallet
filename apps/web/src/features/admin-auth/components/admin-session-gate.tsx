"use client";

import { useEffect } from "react";

import {
  redirectToAdminLogin,
  useAdminSession
} from "@/features/admin-disposals/hooks/use-admin-session";

interface AdminSessionGateProps {
  children: (accessToken: string) => React.ReactNode;
}

export const AdminSessionGate = ({ children }: AdminSessionGateProps) => {
  const session = useAdminSession();

  useEffect(() => {
    if (!session.loading && session.deniedReason) {
      redirectToAdminLogin();
    }
  }, [session.deniedReason, session.loading]);

  if (session.loading) {
    return <p className="text-sm text-zinc-600">Verificando sessão...</p>;
  }

  if (!session.accessToken) {
    return null;
  }

  return <>{children(session.accessToken)}</>;
};
