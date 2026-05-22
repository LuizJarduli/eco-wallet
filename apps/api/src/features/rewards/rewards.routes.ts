import { Router, type RequestHandler } from "express";

import { authenticateJwt } from "../../core/middleware/auth.js";
import { requireMember } from "../../core/middleware/require-member.js";
import type { SupabaseJwtVerifier } from "../../core/supabase/auth-user.service.js";
import type { ProfileRoleLookup } from "../../core/supabase/profile-role.service.js";
import { createRewardsController } from "./rewards.controller.js";
import { SupabaseRewardsRepository } from "./rewards.repository.js";
import {
  createScratchRewardsService,
  type RewardsRepository,
  type ScratchRewardsService
} from "./rewards.service.js";

/**
 * MVP defers admin PATCH for scratch campaigns (`GET/PATCH /v1/admin/config/*`).
 * Campaign probabilities and cost are seeded and read-only until admin config UI ships.
 */
export interface RewardsRoutesDependencies {
  rewardsRepository?: RewardsRepository;
  scratchRewardsService?: ScratchRewardsService;
  jwtVerifier?: SupabaseJwtVerifier;
  profileRoleLookup?: ProfileRoleLookup;
}

export const createRewardsRoutes = ({
  rewardsRepository,
  scratchRewardsService,
  jwtVerifier,
  profileRoleLookup
}: RewardsRoutesDependencies = {}): Router => {
  const router = Router();
  let resolvedService = scratchRewardsService;

  const getService = (): ScratchRewardsService => {
    resolvedService ??= createScratchRewardsService(
      rewardsRepository ?? new SupabaseRewardsRepository()
    );

    return resolvedService;
  };

  const controllerHandler =
    (key: keyof ReturnType<typeof createRewardsController>): RequestHandler =>
    (req, res, next) => {
      const controller = createRewardsController(getService());
      return controller[key](req, res, next);
    };

  router.use(authenticateJwt(jwtVerifier), requireMember(profileRoleLookup));
  router.post("/scratch/play", controllerHandler("playScratch"));

  return router;
};
