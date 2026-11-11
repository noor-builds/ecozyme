import assert from "node:assert/strict";
import express from "express";
import { after, before, test } from "node:test";
import { createTasksRouter } from "../features/tasks/tasks.js";

const user = { id: "25b1d09f-05bd-4e78-b030-172a4a8f7412" };
let tasks = [
  {
    id: 1,
    farmer_id: user.id,
    title: "Check tomato leaves",
    description: "Look for signs of stress.",
    is_completed: false,
  },
];
let cropProfiles = [];
let server;
let baseUrl;

function fakeSupabase() {
  return {
    from(table) {
      const filters = {};
      let updates;
      let insertRows;
      let upsertRow;
      const query = {
        select() {
          return query;
        },
        eq(column, value) {
          filters[column] = String(value);
          return query;
        },
        order: async () => ({
          data: tasks.filter((task) => task.farmer_id === filters.farmer_id),
          error: null,
        }),
        update(values) {
          updates = values;
          return query;
        },
        maybeSingle: async () => {
          const task = tasks.find(
            (item) =>
              String(item.id) === filters.id && item.farmer_id === filters.farmer_id,
          );
          if (!task) return { data: null, error: null };
          Object.assign(task, updates);
          return { data: task, error: null };
        },
        insert(rows) {
          insertRows = rows;
          return query;
        },
        upsert(row, options) {
          assert.equal(table, "farmer_crops");
          assert.equal(options.onConflict, "farmer_id,crop_type,location");
          upsertRow = row;
          return query;
        },
        then(resolve, reject) {
          if (table === "farmer_crops") {
            const existing = cropProfiles.find(
              (item) =>
                item.farmer_id === upsertRow.farmer_id &&
                item.crop_type === upsertRow.crop_type &&
                item.location === upsertRow.location,
            );
            if (existing) Object.assign(existing, upsertRow);
            else cropProfiles.push(upsertRow);
            return Promise.resolve({ data: null, error: null }).then(resolve, reject);
          }

          assert.equal(table, "tasks");
          const created = insertRows.map((row, index) => ({
            ...row,
            id: index + 10,
            is_completed: false,
            created_at: new Date().toISOString(),
          }));
          tasks = [...created, ...tasks];
          return Promise.resolve({ data: created, error: null }).then(resolve, reject);
        },
      };
      return query;
    },
  };
}

const authenticate = (req, _res, next) => {
  req.user = user;
  req.supabase = fakeSupabase();
  next();
};

before(async () => {
  tasks = [
    {
      id: 1,
      farmer_id: user.id,
      title: "Check tomato leaves",
      description: "Look for signs of stress.",
      is_completed: false,
    },
  ];
  cropProfiles = [];
  const app = express();
  app.use(express.json());
  app.use(
    "/api/tasks",
    createTasksRouter({
      authenticate,
      taskGenerator: async () => [
        {
          title: "Inspect seedlings",
          description: "Check moisture and leaf color.",
          crop_stage: "seedling",
          benefits: ["Early issue detection"],
        },
      ],
    }),
  );
  server = app.listen(0, "127.0.0.1");
  await new Promise((resolve, reject) => {
    server.once("listening", resolve);
    server.once("error", reject);
  });
  baseUrl = `http://127.0.0.1:${server.address().port}/api/tasks`;
});

after(async () => {
  await new Promise((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
});

test("loads tasks belonging to the signed-in user", async () => {
  const response = await fetch(`${baseUrl}/`);
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.equal(body.tasks.length, 1);
  assert.equal(body.tasks[0].farmer_id, user.id);
});

test("persists generated tasks under the authenticated user", async () => {
  const response = await fetch(`${baseUrl}/generate`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      cropType: "tomato",
      soilType: "loamy",
      location: "Pune, India",
      season: "monsoon",
      farmerExperience: "beginner",
      farmer_id: "attacker-controlled-id",
    }),
  });
  assert.equal(response.status, 201);
  const body = await response.json();
  assert.equal(body.tasks[0].farmer_id, user.id);
  assert.deepEqual(body.tasks[0].benefits, ["Early issue detection"]);
  assert.deepEqual(cropProfiles[0], {
    farmer_id: user.id,
    crop_type: "tomato",
    soil_type: "loamy",
    location: "Pune, India",
    season: "monsoon",
    farmer_experience: "beginner",
    updated_at: cropProfiles[0].updated_at,
  });
  assert.equal(body.tasks[0].meta.farmerExperience, "beginner");
});

test("requires all crop details before generating tasks", async () => {
  const response = await fetch(`${baseUrl}/generate`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ cropType: "tomato" }),
  });
  assert.equal(response.status, 400);
  assert.match((await response.json()).error, /soilType is required/i);
});

test("updates completion state and timestamp", async () => {
  const response = await fetch(`${baseUrl}/1`, {
    method: "PATCH",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ is_completed: true }),
  });
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.equal(body.task.is_completed, true);
  assert.ok(body.task.completed_at);
});

test("rejects malformed task updates", async () => {
  const response = await fetch(`${baseUrl}/not-an-id`, {
    method: "PATCH",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ is_completed: "yes" }),
  });
  assert.equal(response.status, 400);
});
