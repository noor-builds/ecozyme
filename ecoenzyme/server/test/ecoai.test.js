import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import express from "express";
import app from "../server.js";
import { createEcoAiRouter } from "../features/ecoai/ecoai.js";

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

test("saves crop chat exchanges and returns the signed-in user's history", async () => {
  const history = [];
  const user = { id: "25b1d09f-05bd-4e78-b030-172a4a8f7412" };
  const authenticate = (req, _res, next) => {
    req.user = user;
    req.supabase = {
      from(table) {
        assert.equal(table, "chat_history");
        let inserted;
        const query = {
          select() {
            return query;
          },
          eq(column, value) {
            assert.equal(column, "farmer_id");
            assert.equal(value, user.id);
            return query;
          },
          order() {
            return query;
          },
          limit() {
            return query;
          },
          insert(row) {
            inserted = row;
            return query;
          },
          then(resolve, reject) {
            if (inserted) {
              history.push({ ...inserted, id: history.length + 1 });
              return Promise.resolve({ error: null }).then(resolve, reject);
            }
            return Promise.resolve({
              data: history.filter((item) => item.farmer_id === user.id),
              error: null,
            }).then(resolve, reject);
          },
        };
        return query;
      },
    };
    next();
  };
  const testApp = express();
  testApp.use(express.json());
  testApp.use(
    "/api/ecoai",
    createEcoAiRouter({
      authenticate,
      cropAnalyzer: async () => "The leaves look healthy.",
    }),
  );
  const testServer = testApp.listen(0, "127.0.0.1");
  await new Promise((resolve, reject) => {
    testServer.once("listening", resolve);
    testServer.once("error", reject);
  });
  const testBaseUrl = `http://127.0.0.1:${testServer.address().port}/api/ecoai`;

  try {
    const response = await fetch(`${testBaseUrl}/chat`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        prompt: "  How do these leaves look?  ",
        imageBase64: "aGVsbG8=",
        mimeType: "image/jpeg",
      }),
    });
    assert.equal(response.status, 200);
    assert.equal(history[0].user_message, "How do these leaves look?");
    assert.equal(history[0].assistant_message, "The leaves look healthy.");

    const historyResponse = await fetch(`${testBaseUrl}/history`);
    assert.equal(historyResponse.status, 200);
    const body = await historyResponse.json();
    assert.equal(body.messages.length, 1);
    assert.equal(body.messages[0].farmer_id, user.id);
  } finally {
    await new Promise((resolve, reject) => {
      testServer.close((error) => (error ? reject(error) : resolve()));
    });
  }
});
