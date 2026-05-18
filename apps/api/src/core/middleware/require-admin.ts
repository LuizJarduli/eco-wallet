import type { RequestHandler } from "express";

import { AppError } from "../errors/app-error.js";
import { getProfileRole, type ProfileRoleLookup } from "../supabase/profile-role.service.js";

export const requireAdmin = (
  profileRoleLookup?: ProfileRoleLookup
): RequestHandler => {
  return async (req, _res, next) => {
    try {
      if (!req.userId) {
        throw new AppError("UNAUTHORIZED", 401, "Authentication is required.");
      }

      const lookupRole = profileRoleLookup ?? getProfileRole;
      const role = await lookupRole(req.userId);

      if (role !== "admin") {
        throw new AppError("FORBIDDEN", 403, "Admin access is required.");
      }

      next();
    } catch (error) {
      next(error);
    }
  };
};
