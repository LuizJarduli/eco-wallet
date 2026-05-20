import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { AdminApiError } from "@/core/lib/admin-api";
import { AuditForm } from "@/features/admin-audit/components/audit-form";

describe("AuditForm", () => {
  it("shows BELOW_MIN_VOLUME message when returned by API", () => {
    render(
      <AuditForm
        onSubmit={async () => undefined}
        apiError={
          new AdminApiError(
            "BELOW_MIN_VOLUME",
            "Audited volume is below the active minimum."
          )
        }
      />
    );

    expect(
      screen.getByRole("alert")
    ).toHaveTextContent(/volume auditado está abaixo do mínimo/i);
  });
});
