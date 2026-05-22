import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import {
  QueueFilters,
  type QueueFiltersValue
} from "@/features/admin-disposals/components/queue-filters";

describe("QueueFilters", () => {
  it("calls onFilterChange with selected status", async () => {
    const user = userEvent.setup();
    const onFilterChange = vi.fn();
    const value: QueueFiltersValue = { status: "", priority: "" };

    render(<QueueFilters value={value} onFilterChange={onFilterChange} />);

    await user.selectOptions(
      screen.getByLabelText("Filtrar por status"),
      "awaiting_audit"
    );

    expect(onFilterChange).toHaveBeenCalledWith({
      status: "awaiting_audit",
      priority: ""
    });
  });
});
