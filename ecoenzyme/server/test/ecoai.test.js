import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import app from "../server.js";

let server;
let baseUrl;

before(async () => {
  server = app.listen(0, "127.0.0.1");
  await new Promise((resolve, reject) => {
    server.once("listening", resolve);
    server.once("error", reject);
  });
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  await new Promise((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
});

test("health endpoint reports the server is ready", async () => {
  const response = await fetch(`${baseUrl}/api/health`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: "ok" });
});

test("crop analysis requires an authenticated user", async () => {
  const response = await fetch(`${baseUrl}/api/ecoai/chat`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ prompt: "Describe this crop" }),
  });
  assert.equal(response.status, 401);
  assert.match((await response.json()).error, /sign in/i);
});

test("task endpoints require an authenticated user", async () => {
  const [tasksResponse, generateResponse] = await Promise.all([
    fetch(`${baseUrl}/api/tasks/`),
    fetch(`${baseUrl}/api/tasks/generate`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ cropType: "tomato" }),
    }),
  ]);
  assert.equal(tasksResponse.status, 401);
  assert.equal(generateResponse.status, 401);
});

test("crop analysis supports browser CORS preflight", async () => {
  const response = await fetch(`${baseUrl}/api/ecoai/chat`, {
    method: "OPTIONS",
    headers: {
      origin: "http://localhost:5000",
      "access-control-request-method": "POST",
      "access-control-request-headers": "authorization,content-type",
    },
  });
  assert.equal(response.status, 204);
  assert.equal(response.headers.get("access-control-allow-origin"), "*");
});
