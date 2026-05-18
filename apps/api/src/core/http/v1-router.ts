import { Router } from "express";

import {
  createConfidenceRoutes,
  type ConfidenceRoutesDependencies
} from "../../features/confidence/confidence.routes.js";
import {
  createDisposalRoutes,
  type DisposalRoutesDependencies
} from "../../features/disposals/disposal.routes.js";
import { authenticateJwt } from "../middleware/auth.js";
import { requireAdmin } from "../middleware/require-admin.js";
import type { SupabaseJwtVerifier } from "../supabase/auth-user.service.js";
import type { ProfileRoleLookup } from "../supabase/profile-role.service.js";

export interface V1RouterDependencies
  extends DisposalRoutesDependencies,
    ConfidenceRoutesDependencies {
  jwtVerifier?: SupabaseJwtVerifier;
  profileRoleLookup?: ProfileRoleLookup;
}

export const createV1Router = ({
  confidenceRepository,
  confidenceRetryOptions,
  confidenceScorer,
  confidenceService,
  disposalAdminService,
  disposalRepository,
  jwtVerifier,
  profileRoleLookup
}: V1RouterDependencies = {}): Router => {
  const router = Router();
  const adminRouter = Router();

  adminRouter.get(
    "/protected-stub",
    authenticateJwt(jwtVerifier),
    requireAdmin(profileRoleLookup),
    (req, res) => {
      res.json({ ok: true, userId: req.userId });
    }
  );
  adminRouter.use(
    "/disposals",
    createDisposalRoutes({
      disposalAdminService,
      disposalRepository,
      jwtVerifier,
      profileRoleLookup
    })
  );

  router.use("/admin", adminRouter);
  router.use(
    "/disposals",
    createConfidenceRoutes({
      confidenceRepository,
      confidenceRetryOptions,
      confidenceScorer,
      confidenceService,
      jwtVerifier,
      profileRoleLookup
    })
  );

  return router;
};
