import { loadApiEnv } from "./core/config/load-env.js";
import { createApp } from "./core/http/app.js";

loadApiEnv();

const app = createApp();
const port = Number(process.env.PORT) || 3001;

app.listen(port, () => {
  console.log(`API listening on http://localhost:${port}`);
});
