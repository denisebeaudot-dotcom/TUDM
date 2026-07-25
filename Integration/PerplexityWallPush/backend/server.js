import cors from "cors";
import dotenv from "dotenv";
import express from "express";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

dotenv.config();

const app = express();
const port = Number(process.env.PORT || 8787);
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const dataDir = path.join(__dirname, "data");
const latestPath = path.join(dataDir, "latest_registry.json");

app.use(cors());
app.use(express.json({ limit: "1mb" }));

function round(value) {
  return Math.round(Number(value) * 1000) / 1000;
}

function requireString(value, fieldName) {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Error(`${fieldName} is required.`);
  }
}

function validateRegistry(registry) {
  requireString(registry.room_id, "room_id");
  requireString(registry.wall_id, "wall_id");
  requireString(registry.units, "units");

  if (!Array.isArray(registry.segments) || registry.segments.length === 0) {
    throw new Error("segments must contain at least one segment.");
  }

  const expected = Number(registry.expected_total_width);
  if (!Number.isFinite(expected) || expected <= 0) {
    throw new Error("expected_total_width must be a positive number.");
  }

  const ids = new Set();
  let calculated = 0;

  registry.segments.forEach((segment, index) => {
    requireString(segment.global_id, `segments[${index}].global_id`);
    requireString(segment.kind, `segments[${index}].kind`);
    requireString(segment.label, `segments[${index}].label`);

    if (ids.has(segment.global_id)) {
      throw new Error(`Duplicate global_id found: ${segment.global_id}`);
    }
    ids.add(segment.global_id);

    const width = Number(segment.width);
    if (!Number.isFinite(width) || width <= 0) {
      throw new Error(`segments[${index}].width must be a positive number.`);
    }
    calculated += width;

    if (segment.panel_split) {
      if (!Array.isArray(segment.panel_split)) {
        throw new Error(`segments[${index}].panel_split must be an array.`);
      }
      const panelTotal = segment.panel_split.reduce((sum, item) => sum + Number(item), 0);
      if (Math.abs(panelTotal - width) > 0.001) {
        throw new Error(
          `segments[${index}].panel_split total ${round(panelTotal)} does not equal width ${round(width)}.`
        );
      }
    }
  });

  const delta = Math.abs(calculated - expected);
  if (delta > 0.001) {
    throw new Error(`Wall total mismatch. Expected ${round(expected)} ${registry.units}, got ${round(calculated)}.`);
  }

  return {
    expectedTotalWidth: round(expected),
    calculatedTotalWidth: round(calculated),
    segmentCount: registry.segments.length,
    globalIds: Array.from(ids)
  };
}

function checkPushToken(req) {
  const token = process.env.WALL_PUSH_TOKEN;
  if (!token) return true;
  return req.header("X-Wall-Push-Token") === token;
}

async function summarizeWithPerplexity(registry, validation) {
  if (!process.env.PPLX_API_KEY) {
    return null;
  }

  const apiUrl = process.env.PPLX_API_URL || "https://api.perplexity.ai/chat/completions";
  const model = process.env.PPLX_MODEL || "sonar";
  const chain = registry.segments
    .map((segment) => `${segment.global_id}=${segment.width}${registry.units === "inches" ? "in" : ""}`)
    .join(" | ");

  const response = await fetch(apiUrl, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${process.env.PPLX_API_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model,
      messages: [
        {
          role: "system",
          content: "You are checking a pushed architectural wall registry. Be concise and preserve the structural measurements exactly."
        },
        {
          role: "user",
          content: [
            `Wall registry received for ${registry.room_id} / ${registry.wall_id}.`,
            `Validated total width: ${validation.calculatedTotalWidth} ${registry.units}.`,
            `Chain: ${chain}`,
            "Return one short confirmation sentence and one next-step recommendation."
          ].join("\n")
        }
      ]
    })
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Perplexity API call failed: ${response.status} ${text}`);
  }

  const data = await response.json();
  return data?.choices?.[0]?.message?.content || null;
}

app.get("/health", (_req, res) => {
  res.json({ ok: true, service: "wall-registry-push-proxy" });
});

app.post("/wall-registry", async (req, res) => {
  try {
    if (!checkPushToken(req)) {
      return res.status(401).json({ ok: false, message: "Invalid wall push token." });
    }

    const registry = req.body;
    const validation = validateRegistry(registry);

    await fs.mkdir(dataDir, { recursive: true });
    await fs.writeFile(
      latestPath,
      JSON.stringify(
        {
          received_at: new Date().toISOString(),
          validation,
          registry
        },
        null,
        2
      )
    );

    let perplexitySummary = null;
    try {
      perplexitySummary = await summarizeWithPerplexity(registry, validation);
    } catch (error) {
      perplexitySummary = `Registry saved locally, but Perplexity forwarding failed: ${error.message}`;
    }

    res.json({
      ok: true,
      message: "Wall registry received, validated, and stored.",
      room_id: registry.room_id,
      wall_id: registry.wall_id,
      total_width: validation.calculatedTotalWidth,
      segment_count: validation.segmentCount,
      received_at: new Date().toISOString(),
      next_action: perplexitySummary || "No Perplexity API key configured. Use the stored JSON as the current source of truth."
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      message: error.message
    });
  }
});

app.get("/wall-registry/latest", async (_req, res) => {
  try {
    const text = await fs.readFile(latestPath, "utf8");
    res.type("json").send(text);
  } catch {
    res.status(404).json({ ok: false, message: "No registry has been pushed yet." });
  }
});

app.listen(port, () => {
  console.log(`Wall registry push proxy listening on http://localhost:${port}`);
});
