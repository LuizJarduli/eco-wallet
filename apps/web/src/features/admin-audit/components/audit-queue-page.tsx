"use client";

import { AdminSessionGate } from "@/features/admin-auth/components/admin-session-gate";
import { AuditQueue } from "@/features/admin-audit/components/audit-queue";

export const AuditQueuePage = () => (
  <section className="flex flex-col gap-4">
    <div>
      <h2 className="text-2xl font-semibold text-zinc-900">Auditoria de coleta</h2>
      <p className="text-sm text-zinc-600">
        Confirme o volume coletado para liberar moedas e atualizar o estoque.
      </p>
    </div>

    <AdminSessionGate>
      {(accessToken) => <AuditQueue accessToken={accessToken} />}
    </AdminSessionGate>
  </section>
);
