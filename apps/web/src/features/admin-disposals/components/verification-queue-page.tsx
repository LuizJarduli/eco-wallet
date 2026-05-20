"use client";

import { AdminSessionGate } from "@/features/admin-auth/components/admin-session-gate";
import { VerificationQueue } from "@/features/admin-disposals/components/verification-queue";

export const VerificationQueuePage = () => (
  <section className="flex flex-col gap-4">
    <div>
      <h2 className="text-2xl font-semibold text-zinc-900">Fila de verificação</h2>
      <p className="text-sm text-zinc-600">
        Revise descartes enviados, aprove ou rejeite com motivo.
      </p>
    </div>

    <AdminSessionGate>
      {(accessToken) => <VerificationQueue accessToken={accessToken} />}
    </AdminSessionGate>
  </section>
);
