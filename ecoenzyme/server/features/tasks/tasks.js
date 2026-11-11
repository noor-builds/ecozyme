import express from "express";
import { ChatGoogleGenerativeAI } from "@langchain/google-genai";
import { HumanMessage, SystemMessage } from "@langchain/core/messages";
import { z } from "zod";
import { authenticateUser } from "../../middleware/authenticate_user.js";

const systemPrompt = `You are an expert agricultural advisor specializing in bioenzyme applications for crop improvement.
Generate 5 practical, actionable tasks for the farmer. Return only a JSON array. Every item must contain:
- title: Brief task name
- description: Detailed steps
- frequency: How often to perform
- cropStage: Crop growth stage
- bioenzymeRatio: Dilution ratio
- applicationMethod: How to apply
- benefits: Expected benefits as an array of strings
- precautions: Safety notes as an array of strings
Be cautious: do not invent unsafe application rates. State when the user should follow a product label or consult a local agricultural expert.`;

const TaskZ = z.object({
  title: z.string().trim().min(1).max(160),
  description: z.string().nullable().optional(),
  frequency: z.string().nullable().optional(),
  crop_stage: z.string().nullable().optional(),
  bioenzyme_ratio: z.string().nullable().optional(),
  application_method: z.string().nullable().optional(),
  benefits: z.union([z.string(), z.array(z.string()), z.record(z.string(), z.unknown())]).nullable().optional(),
  precautions: z.union([z.string(), z.array(z.string()), z.record(z.string(), z.unknown())]).nullable().optional(),
});

const TasksArrayZ = z.array(TaskZ).min(1).max(10);
const MAX_FILTER_LENGTH = 100;

function normalizeRawTask(task) {
  return {
    title: task.title || task.name,
    description: task.description || task.details || null,
    frequency: task.frequency || null,
    crop_stage: task.cropStage || task.crop_stage || null,
    bioenzyme_ratio: task.bioenzymeRatio || task.bioenzyme_ratio || null,
    application_method: task.applicationMethod || task.application_method || null,
    benefits: task.benefits || task.benefit || null,
    precautions: task.precautions || task.precaution || null,
  };
}

function parseTaskResponse(content) {
  const text = typeof content === "string"
    ? content
    : content.map((part) => typeof part.text === "string" ? part.text : "").join("");
  const jsonMatch = text.match(/\[[\s\S]*\]/);
  if (!jsonMatch) throw new Error("The AI did not return a task list.");
  const rawTasks = JSON.parse(jsonMatch[0]);
  if (!Array.isArray(rawTasks)) throw new Error("The AI task response must be a list.");

  const parsed = TasksArrayZ.safeParse(rawTasks.map(normalizeRawTask));
  if (!parsed.success) {
    throw new Error("The AI task response did not match the expected format.");
  }
  return parsed.data;
}

function validatedGenerationInput(body) {
  const fields = ["cropType", "soilType", "location", "season", "farmerExperience"];
  const input = {};
  for (const field of fields) {
    const value = body[field];
    if (typeof value !== "string" || value.trim().length === 0) {
      return { error: `${field} is required.` };
    }
    if (value.length > MAX_FILTER_LENGTH) {
      return { error: `${field} must be no longer than ${MAX_FILTER_LENGTH} characters.` };
    }
    input[field] = value.trim();
  }
  return { input };
}

async function generateTasks(input) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw Object.assign(new Error("Task generation is not configured."), { status: 503 });

  const model = new ChatGoogleGenerativeAI({
    apiKey,
    model: process.env.GEMINI_MODEL || "gemini-2.5-flash",
    temperature: Number(process.env.GEMINI_TEMPERATURE) || 0.4,
  });
  const prompt = `Generate crop-care tasks using:
- Crop: ${input.cropType || "general crops"}
- Soil: ${input.soilType || "not specified"}
- Location: ${input.location || "not specified"}
- Season: ${input.season || "not specified"}
- Experience: ${input.farmerExperience || "beginner"}`;
  const response = await model.invoke([
    new SystemMessage(systemPrompt),
    new HumanMessage(prompt),
  ]);
  return parseTaskResponse(response.content);
}

function createTasksRouter({
  authenticate = authenticateUser,
  taskGenerator = generateTasks,
} = {}) {
  const router = express.Router();

  router.get("/", authenticate, async (req, res) => {
    const { data, error } = await req.supabase
      .from("tasks")
      .select("*")
      .eq("farmer_id", req.user.id)
      .order("created_at", { ascending: false });

    if (error) {
      console.error("Could not load tasks:", error.message);
      return res.status(500).json({ error: "Could not load your tasks." });
    }
    return res.json({ tasks: data });
  });

  router.patch("/:id", authenticate, async (req, res) => {
    if (!/^[1-9]\d*$/.test(req.params.id)) {
      return res.status(400).json({ error: "Task ID must be a positive integer." });
    }
    if (typeof req.body?.is_completed !== "boolean") {
      return res.status(400).json({ error: "is_completed must be true or false." });
    }

    const isCompleted = req.body.is_completed;
    const { data, error } = await req.supabase
      .from("tasks")
      .update({
        is_completed: isCompleted,
        completed_at: isCompleted ? new Date().toISOString() : null,
      })
      .eq("id", req.params.id)
      .eq("farmer_id", req.user.id)
      .select("*")
      .maybeSingle();

    if (error) {
      console.error("Could not update task:", error.message);
      return res.status(500).json({ error: "Could not update this task." });
    }
    if (!data) return res.status(404).json({ error: "Task not found." });
    return res.json({ task: data });
  });

  router.post("/generate", authenticate, async (req, res) => {
    const validation = validatedGenerationInput(req.body || {});
    if (validation.error) return res.status(400).json({ error: validation.error });

    try {
      const tasks = await taskGenerator(validation.input);
      const { error: cropError } = await req.supabase
        .from("farmer_crops")
        .upsert(
          {
            farmer_id: req.user.id,
            crop_type: validation.input.cropType,
            soil_type: validation.input.soilType,
            location: validation.input.location,
            season: validation.input.season,
            farmer_experience: validation.input.farmerExperience,
            updated_at: new Date().toISOString(),
          },
          { onConflict: "farmer_id,crop_type,location" },
        );

      if (cropError) {
        console.error("Could not save crop profile:", cropError.message);
        return res.status(500).json({ error: "Your crop details could not be saved." });
      }

      const rows = tasks.map((task) => ({
        ...task,
        farmer_id: req.user.id,
        benefits: typeof task.benefits === "string" ? [task.benefits] : task.benefits,
        precautions: typeof task.precautions === "string" ? [task.precautions] : task.precautions,
        meta: validation.input,
      }));
      const { data, error } = await req.supabase
        .from("tasks")
        .insert(rows)
        .select("*");

      if (error) {
        console.error("Could not save generated tasks:", error.message);
        return res.status(500).json({ error: "Generated tasks could not be saved." });
      }
      return res.status(201).json({ tasks: data });
    } catch (error) {
      console.error("Task generation failed:", error.message);
      return res.status(error.status || 502).json({
        error: error.status ? error.message : "Could not generate tasks. Please try again.",
      });
    }
  });

  return router;
}

export { createTasksRouter, parseTaskResponse, validatedGenerationInput };
export default createTasksRouter();
