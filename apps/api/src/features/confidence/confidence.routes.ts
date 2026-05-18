import { Router, type RequestHandler } from "express";

import { authenticateJwt } from "../../core/middleware/auth.js";
import { requireMember } from "../../core/middleware/require-member.js";
import type { SupabaseJwtVerifier } from "../../core/supabase/auth-user.service.js";
import type { ProfileRoleLookup } from "../../core/supabase/profile-role.service.js";
import { createConfidenceController } from "./confidence.controller.js";
import { SupabaseConfidenceRepository } from "./confidence.repository.js";
import {
  createConfidenceService,
  type ConfidenceService,
  type RetryOptions
} from "./confidence.service.js";
import type {
  ConfidenceRepository,
  ConfidenceScorer
} from "./confidence.types.js";

export interface ConfidenceRoutesDependencies {
  confidenceRepository?: ConfidenceRepository;
  confidenceScorer?: ConfidenceScorer;
  confidenceService?: ConfidenceService;
  confidenceRetryOptions?: Partial<RetryOptions>;
  jwtVerifier?: SupabaseJwtVerifier;
  profileRoleLookup?: ProfileRoleLookup;
}

export const createConfidenceRoutes = ({
  confidenceRepository,
  confidenceScorer,
  confidenceService,
  confidenceRetryOptions,
  jwtVerifier,
  profileRoleLookup
}: ConfidenceRoutesDependencies = {}): Router => {
  const router = Router();
  let resolvedService = confidenceService;

  const getService = (): ConfidenceService => {
    resolvedService ??= createConfidenceService(
      confidenceRepository ?? new SupabaseConfidenceRepository(),
      confidenceScorer,
      confidenceRetryOptions
    );

    return resolvedService;
  };

  const controllerHandler =
    (key: keyof ReturnType<typeof createConfidenceController>): RequestHandler =>
    (req, res, next) => {
      const controller = createConfidenceController(getService());
      return controller[key](req, res, next);
    };

  router.use(authenticateJwt(jwtVerifier), requireMember(profileRoleLookup));
  router.post("/:id/score", controllerHandler("score"));

  return router;
};
