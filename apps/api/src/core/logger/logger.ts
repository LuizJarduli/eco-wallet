export interface Logger {
  error: (message: string, context?: Record<string, unknown>) => void;
  info: (message: string, context?: Record<string, unknown>) => void;
}

export const logger: Logger = {
  error: (message, context) => {
    console.error(message, context ?? {});
  },
  info: (message, context) => {
    console.log(message, context ?? {});
  }
};
