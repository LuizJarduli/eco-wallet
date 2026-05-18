import cors from "cors";
import express, { type Express } from "express";

import { errorHandler } from "../errors/error-handler.js";
import { notFoundHandler } from "../errors/not-found.js";
import { createV1Router, type V1RouterDependencies } from "./v1-router.js";
import "./request-context.js";

export type AppDependencies = V1RouterDependencies;

export const createApp = (dependencies: AppDependencies = {}): Express => {
  const app = express();

  app.use(cors());
  app.use(express.json());

  app.get("/health", (_req, res) => {
    res.json({ status: "ok", service: "eco-wallet-api" });
  });

  app.use("/v1", createV1Router(dependencies));
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
};
