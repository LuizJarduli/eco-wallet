import { z } from "zod";

export const scratchPlayBodySchema = z
  .object({
    campaignId: z.string().uuid()
  })
  .strict();

export type ScratchPlayBody = z.infer<typeof scratchPlayBodySchema>;
