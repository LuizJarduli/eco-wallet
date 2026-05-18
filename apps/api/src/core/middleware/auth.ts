import type { RequestHandler } from "express";

import { AppError } from "../errors/app-error.js";
import { verifySupabaseJwt, type SupabaseJwtVerifier } from "../supabase/auth-user.service.js";

const extractBearerToken = (authorizationHeader: string | undefined): string => {
  if (!authorizationHeader) {
    throw new AppError("UNAUTHORIZED", 401, "Missing Authorization header.");
  }

  const [scheme, token] = authorizationHeader.split(" ");

  if (scheme !== "Bearer" || !token) {
    throw new AppError("UNAUTHORIZED", 401, "Invalid Authorization header.");
  }

  return token;
};

export const authenticateJwt = (
  jwtVerifier: SupabaseJwtVerifier = verifySupabaseJwt
): RequestHandler => {
  return async (req, _res, next) => {
    try {
      const token = extractBearerToken(req.header("authorization"));
      const userId = await jwtVerifier(token);

      if (!userId) {
        throw new AppError("UNAUTHORIZED", 401, "Invalid or expired token.");
      }

      req.userId = userId;
      next();
    } catch (error) {
      next(error);
    }
  };
};
