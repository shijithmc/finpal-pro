// FinPal Pro — AI bill scan proxy (PBI-016, issues #61-#64).
//
// Routes (HTTP API v2, Cognito JWT authorizer):
//   POST /v1/scan          — parse a bill image via Gemini, enforce quota
//   GET  /v1/scan/quota    — remaining free-tier scans for the month
//   POST /v1/scan/feedback — record user corrections (accuracy telemetry)
//
// Security invariants:
//   - Gemini API key lives in Secrets Manager only — never reaches the client.
//   - Quota is enforced server-side with an atomic conditional ADD.
//   - Bill images are relayed to Gemini and never persisted anywhere.
import {
  DynamoDBClient,
  GetItemCommand,
  PutItemCommand,
  UpdateItemCommand,
} from "@aws-sdk/client-dynamodb";
import {
  GetSecretValueCommand,
  SecretsManagerClient,
} from "@aws-sdk/client-secrets-manager";
import { randomUUID } from "node:crypto";

const TABLE_NAME = process.env.TABLE_NAME;
const GEMINI_SECRET_ARN = process.env.GEMINI_SECRET_ARN;
const GEMINI_MODEL = process.env.GEMINI_MODEL ?? "gemini-2.5-flash";
const FREE_SCAN_LIMIT = parseInt(process.env.FREE_SCAN_LIMIT ?? "10", 10);
const GLOBAL_MONTHLY_SCAN_CAP = parseInt(
  process.env.GLOBAL_MONTHLY_SCAN_CAP ?? "5000",
  10,
);

// ~3.7 MB binary after base64 — stays under the 6 MB sync-invoke payload cap.
const MAX_IMAGE_BASE64_CHARS = 5_000_000;
const ALLOWED_MIME_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
]);
const MAX_CATEGORIES = 300;
const FEEDBACK_FIELDS = new Set(["amount", "merchant", "date", "category"]);
const TELEMETRY_TTL_SECONDS = 90 * 24 * 3600;

const ddb = new DynamoDBClient({});
const secrets = new SecretsManagerClient({});

// Cached across warm invocations — Secrets Manager is not on the hot path.
let cachedGeminiKey = null;

export const handler = async (event) => {
  const started = Date.now();
  const routeKey = event.routeKey ?? "";
  const sub = event.requestContext?.authorizer?.jwt?.claims?.sub;

  if (!sub) {
    return problem(401, "UNAUTHORIZED", "Missing or invalid access token.");
  }

  try {
    let response;
    if (routeKey === "POST /v1/scan") {
      response = await handleScan(sub, event.body, event.isBase64Encoded);
    } else if (routeKey === "GET /v1/scan/quota") {
      response = await handleQuota(sub);
    } else if (routeKey === "POST /v1/scan/feedback") {
      response = await handleFeedback(sub, event.body, event.isBase64Encoded);
    } else {
      response = problem(404, "NOT_FOUND", `Unknown route: ${routeKey}`);
    }
    log("INFO", routeKey, sub, response.statusCode, Date.now() - started);
    return response;
  } catch (err) {
    log("ERROR", routeKey, sub, 500, Date.now() - started, err);
    return problem(500, "INTERNAL", "Unexpected error processing the request.");
  }
};

// ── POST /v1/scan ────────────────────────────────────────────────────────────

async function handleScan(sub, rawBody, isBase64Encoded) {
  const body = parseBody(rawBody, isBase64Encoded);
  const validationError = validateScanRequest(body);
  if (validationError) {
    return problem(400, "INVALID_IMAGE", validationError);
  }

  const month = monthKeyIst();

  // Reserve one quota unit atomically — fails closed at the boundary.
  const userCount = await reserveCounter(
    `USER#${sub}`,
    `AISCAN#QUOTA#${month}`,
    FREE_SCAN_LIMIT,
  );
  if (userCount === null) {
    return problem(
      429,
      "QUOTA_EXHAUSTED",
      `Monthly free scan limit of ${FREE_SCAN_LIMIT} reached.`,
      { used: FREE_SCAN_LIMIT, limit: FREE_SCAN_LIMIT, remaining: 0 },
    );
  }

  // Global spend circuit breaker.
  const globalCount = await reserveCounter(
    "SYSTEM",
    `AISCAN#GLOBAL#${month}`,
    GLOBAL_MONTHLY_SCAN_CAP,
  );
  if (globalCount === null) {
    await refundCounter(`USER#${sub}`, `AISCAN#QUOTA#${month}`);
    return problem(
      503,
      "SERVICE_UNAVAILABLE",
      "AI scanning is temporarily unavailable. Please enter the expense manually.",
    );
  }

  const scansRemaining = Math.max(0, FREE_SCAN_LIMIT - userCount);
  const scanId = randomUUID();

  let parsed;
  try {
    parsed = await callGemini(body);
  } catch (err) {
    await refundCounter(`USER#${sub}`, `AISCAN#QUOTA#${month}`);
    await refundCounter("SYSTEM", `AISCAN#GLOBAL#${month}`);
    if (err instanceof GeminiAuthError) {
      log("ERROR", "gemini-auth", sub, 503, 0, err);
      return problem(
        503,
        "SERVICE_UNAVAILABLE",
        "AI scanning is temporarily unavailable. Please enter the expense manually.",
      );
    }
    log("ERROR", "gemini-call", sub, 502, 0, err);
    return problem(
      502,
      "PARSE_FAILED",
      "The bill could not be read. Try a clearer photo or enter the expense manually.",
    );
  }

  if (!parsed.isBill) {
    await refundCounter(`USER#${sub}`, `AISCAN#QUOTA#${month}`);
    await refundCounter("SYSTEM", `AISCAN#GLOBAL#${month}`);
    await writeTelemetry(sub, scanId, "NOT_A_BILL", parsed);
    return problem(
      422,
      "NOT_A_BILL",
      "This image does not look like a bill or receipt.",
    );
  }

  const result = sanitizeParse(parsed, body.categories);
  const outcome =
    result.amountPaise !== null &&
    result.merchant !== null &&
    result.dateIso !== null
      ? "SUCCESS"
      : "PARTIAL";
  await writeTelemetry(sub, scanId, outcome, result);

  return json(200, {
    scanId,
    amountPaise: result.amountPaise,
    merchant: result.merchant,
    dateIso: result.dateIso,
    categoryId: result.categoryId,
    confidence: result.confidence,
    scansRemaining,
  });
}

// ── GET /v1/scan/quota ───────────────────────────────────────────────────────

async function handleQuota(sub) {
  const month = monthKeyIst();
  const item = await ddb.send(
    new GetItemCommand({
      TableName: TABLE_NAME,
      Key: {
        PK: { S: `USER#${sub}` },
        SK: { S: `AISCAN#QUOTA#${month}` },
      },
      ConsistentRead: true,
    }),
  );
  const used = item.Item ? parseInt(item.Item.scanCount?.N ?? "0", 10) : 0;
  return json(200, {
    used,
    limit: FREE_SCAN_LIMIT,
    remaining: Math.max(0, FREE_SCAN_LIMIT - used),
  });
}

// ── POST /v1/scan/feedback ───────────────────────────────────────────────────

async function handleFeedback(sub, rawBody, isBase64Encoded) {
  const body = parseBody(rawBody, isBase64Encoded);
  if (
    typeof body?.scanId !== "string" ||
    !Array.isArray(body?.correctedFields) ||
    body.correctedFields.length > 4 ||
    !body.correctedFields.every(
      (f) => typeof f === "string" && FEEDBACK_FIELDS.has(f),
    )
  ) {
    return problem(
      400,
      "INVALID_FEEDBACK",
      "scanId and correctedFields (amount|merchant|date|category) are required.",
    );
  }

  try {
    await ddb.send(
      new UpdateItemCommand({
        TableName: TABLE_NAME,
        Key: {
          PK: { S: `USER#${sub}` },
          SK: { S: `AISCAN#SCAN#${body.scanId}` },
        },
        UpdateExpression: "SET correctedFields = :f, correctedAt = :at",
        ConditionExpression: "attribute_exists(PK)",
        ExpressionAttributeValues: {
          ":f": { SS: dedupe(body.correctedFields) },
          ":at": { S: new Date().toISOString() },
        },
      }),
    );
  } catch (err) {
    if (err.name === "ConditionalCheckFailedException") {
      return problem(404, "SCAN_NOT_FOUND", "Unknown scanId for this user.");
    }
    throw err;
  }
  return { statusCode: 204, body: "" };
}

// ── Gemini ───────────────────────────────────────────────────────────────────

class GeminiAuthError extends Error {}

async function callGemini(body) {
  const apiKey = await getGeminiKey();
  const categoryLines = body.categories
    .map((c) => `${c.id} — ${c.name}`)
    .join("\n");

  const prompt = [
    "You parse photos of Indian retail bills, receipts, and invoices.",
    "Extract the grand total actually payable (after taxes and discounts),",
    "the merchant or store name, and the bill date.",
    "Then pick the single best matching expense category from this list,",
    "returning its exact id:",
    categoryLines,
    "",
    "Rules:",
    "- isBill is false when the image is not a bill, receipt, or invoice.",
    "- amountPaise: grand total in paise (rupees × 100), as an integer; null if unreadable.",
    "- merchant: business name; null if unreadable.",
    "- dateIso: bill date as YYYY-MM-DD; null if unreadable.",
    "- categoryId: exactly one id from the list above; null if no good match.",
    "- confidence: your overall extraction confidence between 0 and 1.",
  ].join("\n");

  const request = {
    contents: [
      {
        parts: [
          {
            inline_data: { mime_type: body.mimeType, data: body.imageBase64 },
          },
          { text: prompt },
        ],
      },
    ],
    generationConfig: {
      response_mime_type: "application/json",
      response_schema: {
        type: "OBJECT",
        properties: {
          isBill: { type: "BOOLEAN" },
          amountPaise: { type: "INTEGER", nullable: true },
          merchant: { type: "STRING", nullable: true },
          dateIso: { type: "STRING", nullable: true },
          categoryId: { type: "STRING", nullable: true },
          confidence: { type: "NUMBER" },
        },
        required: ["isBill", "confidence"],
      },
    },
  };

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": apiKey,
      },
      body: JSON.stringify(request),
      signal: AbortSignal.timeout(25_000),
    },
  );

  if (response.status === 401 || response.status === 403) {
    throw new GeminiAuthError(`Gemini auth failed: ${response.status}`);
  }
  if (!response.ok) {
    throw new Error(`Gemini HTTP ${response.status}`);
  }

  const data = await response.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (typeof text !== "string") {
    throw new Error("Gemini returned no candidate text");
  }
  const parsed = JSON.parse(text);
  if (typeof parsed.isBill !== "boolean") {
    throw new Error("Gemini response failed schema validation: isBill");
  }
  return parsed;
}

async function getGeminiKey() {
  if (cachedGeminiKey) return cachedGeminiKey;
  const secret = await secrets.send(
    new GetSecretValueCommand({ SecretId: GEMINI_SECRET_ARN }),
  );
  cachedGeminiKey = (secret.SecretString ?? "").trim();
  if (!cachedGeminiKey) {
    throw new GeminiAuthError("Gemini API key secret is empty");
  }
  return cachedGeminiKey;
}

/// Enforces server-side trust: only values that survive validation reach the
/// client, and categoryId must come from the caller-supplied allowlist.
function sanitizeParse(parsed, categories) {
  const validIds = new Set(categories.map((c) => c.id));
  const amountPaise =
    Number.isInteger(parsed.amountPaise) && parsed.amountPaise > 0
      ? parsed.amountPaise
      : null;
  const merchant =
    typeof parsed.merchant === "string" && parsed.merchant.trim().length > 0
      ? parsed.merchant.trim().slice(0, 255)
      : null;
  const dateIso =
    typeof parsed.dateIso === "string" &&
    /^\d{4}-\d{2}-\d{2}$/.test(parsed.dateIso)
      ? parsed.dateIso
      : null;
  const categoryId =
    typeof parsed.categoryId === "string" && validIds.has(parsed.categoryId)
      ? parsed.categoryId
      : null;
  const confidence =
    typeof parsed.confidence === "number"
      ? Math.min(1, Math.max(0, parsed.confidence))
      : 0;
  return { amountPaise, merchant, dateIso, categoryId, confidence };
}

// ── Quota counters ───────────────────────────────────────────────────────────

/// Atomically reserves one unit. Returns the new count, or null when the
/// limit is already reached (the reservation did not happen).
async function reserveCounter(pk, sk, limit) {
  try {
    const result = await ddb.send(
      new UpdateItemCommand({
        TableName: TABLE_NAME,
        Key: { PK: { S: pk }, SK: { S: sk } },
        UpdateExpression: "ADD scanCount :one",
        ConditionExpression:
          "attribute_not_exists(scanCount) OR scanCount < :limit",
        ExpressionAttributeValues: {
          ":one": { N: "1" },
          ":limit": { N: String(limit) },
        },
        ReturnValues: "UPDATED_NEW",
      }),
    );
    return parseInt(result.Attributes.scanCount.N, 10);
  } catch (err) {
    if (err.name === "ConditionalCheckFailedException") return null;
    throw err;
  }
}

/// Refunds a reserved unit after a failed parse — failures never consume quota.
async function refundCounter(pk, sk) {
  try {
    await ddb.send(
      new UpdateItemCommand({
        TableName: TABLE_NAME,
        Key: { PK: { S: pk }, SK: { S: sk } },
        UpdateExpression: "ADD scanCount :minusOne",
        ConditionExpression: "attribute_exists(scanCount) AND scanCount > :zero",
        ExpressionAttributeValues: {
          ":minusOne": { N: "-1" },
          ":zero": { N: "0" },
        },
      }),
    );
  } catch (err) {
    // A failed refund must never fail the request — log and continue.
    log("WARN", "quota-refund", pk, 0, 0, err);
  }
}

// ── Telemetry (text only — never the image) ──────────────────────────────────

async function writeTelemetry(sub, scanId, outcome, fields) {
  const now = new Date();
  const item = {
    PK: { S: `USER#${sub}` },
    SK: { S: `AISCAN#SCAN#${scanId}` },
    entityType: { S: "AiScanTelemetry" },
    outcome: { S: outcome },
    model: { S: GEMINI_MODEL },
    confidence: { N: String(fields.confidence ?? 0) },
    createdAt: { S: now.toISOString() },
    TTL: { N: String(Math.floor(now.getTime() / 1000) + TELEMETRY_TTL_SECONDS) },
  };
  if (fields.amountPaise != null) {
    item.amountPaise = { N: String(fields.amountPaise) };
  }
  if (fields.merchant != null) item.merchant = { S: fields.merchant };
  if (fields.dateIso != null) item.dateIso = { S: fields.dateIso };
  if (fields.categoryId != null) item.categoryId = { S: fields.categoryId };

  try {
    await ddb.send(new PutItemCommand({ TableName: TABLE_NAME, Item: item }));
  } catch (err) {
    // Telemetry must never fail the scan — log and continue.
    log("WARN", "telemetry-write", sub, 0, 0, err);
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function validateScanRequest(body) {
  if (!body || typeof body !== "object") return "Request body must be JSON.";
  if (
    typeof body.imageBase64 !== "string" ||
    body.imageBase64.length === 0 ||
    body.imageBase64.length > MAX_IMAGE_BASE64_CHARS
  ) {
    return "imageBase64 is required and must be at most 3.7 MB of image data.";
  }
  if (!ALLOWED_MIME_TYPES.has(body.mimeType)) {
    return "mimeType must be one of image/jpeg, image/png, image/webp, image/heic.";
  }
  if (
    !Array.isArray(body.categories) ||
    body.categories.length === 0 ||
    body.categories.length > MAX_CATEGORIES ||
    !body.categories.every(
      (c) =>
        c &&
        typeof c.id === "string" &&
        c.id.length > 0 &&
        c.id.length <= 64 &&
        typeof c.name === "string" &&
        c.name.length > 0 &&
        c.name.length <= 60,
    )
  ) {
    return "categories must be a non-empty array of {id, name}.";
  }
  return null;
}

/// Calendar month in IST (UTC+5:30) — the product's home market timezone.
function monthKeyIst(now = new Date()) {
  const ist = new Date(now.getTime() + 5.5 * 3600 * 1000);
  const year = ist.getUTCFullYear();
  const month = String(ist.getUTCMonth() + 1).padStart(2, "0");
  return `${year}-${month}`;
}

function parseBody(rawBody, isBase64Encoded) {
  if (typeof rawBody !== "string" || rawBody.length === 0) return null;
  try {
    const text = isBase64Encoded
      ? Buffer.from(rawBody, "base64").toString("utf8")
      : rawBody;
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function dedupe(values) {
  return [...new Set(values)];
}

function json(statusCode, payload) {
  return {
    statusCode,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  };
}

/// RFC 7807 Problem Details with a machine-readable `code` for client mapping.
function problem(status, code, detail, extra = {}) {
  return {
    statusCode: status,
    headers: { "Content-Type": "application/problem+json" },
    body: JSON.stringify({
      type: "about:blank",
      title: code,
      status,
      detail,
      code,
      ...extra,
    }),
  };
}

function log(level, operation, principal, status, durationMs, err) {
  console.log(
    JSON.stringify({
      level,
      operation,
      principal,
      status,
      durationMs,
      errorName: err?.name ?? null,
      errorMessage: err?.message ?? null,
    }),
  );
}
