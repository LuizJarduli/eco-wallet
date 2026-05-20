import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { QueueFilters } from "@/features/admin-disposals/components/queue-filters";

describe("QueueFilters priority", () => {
  it("calls onFilterChange with selected priority", async () => {
    const user = userEvent.setup();
    const onFilterChange = vi.fn();

    render(
      <QueueFilters
        value={{ status: "", priority: "" }}
        onFilterChange={onFilterChange}
      />
    );

    await user.selectOptions(
      screen.getByLabelText("Filtrar por prioridade"),
      "high"
    );

    expect(onFilterChange).toHaveBeenCalledWith({
      status: "",
      priority: "high"
    });
  });
});
