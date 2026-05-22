import type { ErrorRequestHandler } from "express";

import { isAppError } from "./app-error.js";

export const errorHandler: ErrorRequestHandler = (error, _req, res, _next) => {
  if (isAppError(error)) {
    res.status(error.statusCode).json({
      error: {
        code: error.code,
        message: error.message
      }
    });
    return;
  }

  if (process.env.NODE_ENV !== "production") {
    console.error("[api] unhandled error:", error);
  }

  res.status(500).json({
    error: {
      code: "INTERNAL_ERROR",
      message: "An unexpected error occurred."
    }
  });
};
