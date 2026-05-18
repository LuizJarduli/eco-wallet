import { Router } from "express";

import { authenticateJwt } from "../middleware/auth.js";
import { requireAdmin } from "../middleware/require-admin.js";
import type { SupabaseJwtVerifier } from "../supabase/auth-user.service.js";
import type { ProfileRoleLookup } from "../supabase/profile-role.service.js";

export interface V1RouterDependencies {
  jwtVerifier?: SupabaseJwtVerifier;
  profileRoleLookup?: ProfileRoleLookup;
}

export const createV1Router = ({
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

  router.use("/admin", adminRouter);

  return router;
};
