import { cleanup, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";

import { ApiErrorBanner } from "@/core/ui/api-error-banner";

describe("ApiErrorBanner", () => {
  afterEach(() => {
    cleanup();
  });

  it("renders custom message when code is unknown", () => {
    render(<ApiErrorBanner message="Erro customizado" />);

    expect(screen.getByRole("alert")).toHaveTextContent("Erro customizado");
  });

  it("maps BELOW_MIN_VOLUME code to pt-BR copy", () => {
    render(<ApiErrorBanner code="BELOW_MIN_VOLUME" />);

    expect(screen.getByRole("alert")).toHaveTextContent(
      /volume auditado está abaixo do mínimo/i
    );
  });
});
