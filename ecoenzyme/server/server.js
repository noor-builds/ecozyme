import express from "express";
import dotenv from "dotenv";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import ecoAiRouter from "./features/ecoai/ecoai.js";
import tasksRouter from "./features/tasks/tasks.js";

dotenv.config();

const app = express();
app.use((req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", process.env.CORS_ORIGIN || "*");
  res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, PATCH, OPTIONS");

  if (req.method === "OPTIONS") {
    return res.sendStatus(204);
  }

  next();
});
app.use(express.json({ limit: "10mb" }));

app.use("/api/ecoai", ecoAiRouter);
app.use("/api/tasks", tasksRouter);

app.get("/api/health", (req, res) => {
  res.json({ status: "ok" });
});

export default app;

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}