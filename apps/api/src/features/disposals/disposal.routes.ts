import { Router, type RequestHandler } from "express";

import { logger } from "../../core/logger/logger.js";
import { authenticateJwt } from "../../core/middleware/auth.js";
import { requireAdmin } from "../../core/middleware/require-admin.js";
import type { SupabaseJwtVerifier } from "../../core/supabase/auth-user.service.js";
import type { ProfileRoleLookup } from "../../core/supabase/profile-role.service.js";
import { createNotificationService } from "../notifications/notification.service.js";
import { createPushProviderFromEnv } from "../notifications/push-provider.factory.js";
import { createDisposalController } from "./disposal.controller.js";
import { SupabaseDisposalRepository } from "./disposal.repository.js";
import {
  createDisposalAdminService,
  type DisposalAdminService,
  type DisposalRepository
} from "./disposal.service.js";

export interface DisposalRoutesDependencies {
  disposalAdminService?: DisposalAdminService;
  disposalRepository?: DisposalRepository;
  jwtVerifier?: SupabaseJwtVerifier;
  profileRoleLookup?: ProfileRoleLookup;
}

export const createDisposalRoutes = ({
  disposalAdminService,
  disposalRepository,
  jwtVerifier,
  profileRoleLookup
}: DisposalRoutesDependencies = {}): Router => {
  const router = Router();
  let resolvedService = disposalAdminService;

  const getService = (): DisposalAdminService => {
    resolvedService ??= createDisposalAdminService(
      disposalRepository ?? new SupabaseDisposalRepository(),
      logger,
      createNotificationService({
        pushProvider: createPushProviderFromEnv()
      })
    );

    return resolvedService;
  };

  const controllerHandler =
    (key: keyof ReturnType<typeof createDisposalController>): RequestHandler =>
    (req, res, next) => {
      const controller = createDisposalController(getService());
      return controller[key](req, res, next);
    };

  router.use(authenticateJwt(jwtVerifier), requireAdmin(profileRoleLookup));

  router.get("/", controllerHandler("list"));
  router.post("/:id/approve", controllerHandler("approve"));
  router.post("/:id/reject", controllerHandler("reject"));
  router.post("/:id/audit", controllerHandler("audit"));

  return router;
};
