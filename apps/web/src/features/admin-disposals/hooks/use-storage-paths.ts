"use client";

import { useEffect, useMemo, useState } from "react";

import { createSupabaseBrowserClient } from "@/core/lib/supabase";

export const useStoragePaths = (submissionIds: string[]) => {
  const [pathsById, setPathsById] = useState<Record<string, string>>({});
  const idsKey = useMemo(() => submissionIds.join(","), [submissionIds]);

  useEffect(() => {
    let cancelled = false;

    if (submissionIds.length === 0) {
      return () => {
        cancelled = true;
      };
    }

    const supabase = createSupabaseBrowserClient();

    void supabase
      .from("disposal_submissions")
      .select("id, storage_path")
      .in("id", submissionIds)
      .then(({ data }) => {
        if (cancelled) {
          return;
        }

        const next: Record<string, string> = {};

        for (const row of data ?? []) {
          if (row.storage_path) {
            next[row.id] = row.storage_path;
          }
        }

        setPathsById(next);
      });

    return () => {
      cancelled = true;
    };
  }, [idsKey, submissionIds]);

  return submissionIds.length === 0 ? {} : pathsById;
};

export const buildPhotoUrl = (storagePath: string) =>
  `/api/admin/photo?path=${encodeURIComponent(storagePath)}`;
