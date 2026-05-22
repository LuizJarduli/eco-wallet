"use client";

import { disposalStatuses } from "@eco-wallet/domain";

import type { ReviewPriority } from "@/core/lib/admin-api";
import { formFieldClassName, formLabelClassName } from "@/core/ui/form-controls";
import {
  disposalStatusLabels,
  reviewPriorityLabels
} from "@/features/admin-disposals/constants";

export interface QueueFiltersValue {
  status: string;
  priority: string;
}

interface QueueFiltersProps {
  value: QueueFiltersValue;
  onFilterChange: (value: QueueFiltersValue) => void;
}

export const QueueFilters = ({ value, onFilterChange }: QueueFiltersProps) => (
  <div className="flex flex-wrap gap-4">
    <label className="flex flex-col gap-1 text-sm">
      <span className={formLabelClassName}>Status</span>
      <select
        aria-label="Filtrar por status"
        className={formFieldClassName}
        value={value.status}
        onChange={(event) =>
          onFilterChange({ ...value, status: event.target.value })
        }
      >
        <option value="">Todos</option>
        {disposalStatuses.map((status) => (
          <option key={status} value={status}>
            {disposalStatusLabels[status]}
          </option>
        ))}
      </select>
    </label>

    <label className="flex flex-col gap-1 text-sm">
      <span className={formLabelClassName}>Prioridade de revisão</span>
      <select
        aria-label="Filtrar por prioridade"
        className={formFieldClassName}
        value={value.priority}
        onChange={(event) =>
          onFilterChange({ ...value, priority: event.target.value })
        }
      >
        <option value="">Todas</option>
        {(Object.keys(reviewPriorityLabels) as ReviewPriority[]).map(
          (priority) => (
            <option key={priority} value={priority}>
              {reviewPriorityLabels[priority]}
            </option>
          )
        )}
      </select>
    </label>
  </div>
);
