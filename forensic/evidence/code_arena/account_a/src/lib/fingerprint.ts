import { execSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { db } from "@/db";
import { sql } from "drizzle-orm";

export const REFERENCE_TEMPLATE_ID = "nlhz8vlwyupq845jsdg9";

function sh(cmd: string): string | null {
  try {
    return execSync(cmd, { encoding: "utf8", timeout: 5000 }).trim() || null;
  } catch {
    return null;
  }
}

function readText(p: string): string | null {
  try {
    return existsSync(p) ? readFileSync(p, "utf8").trim() : null;
  } catch {
    return null;
  }
}

function humanBytes(n: number | null): string {
  if (n === null || !Number.isFinite(n)) return "unknown";
  return `${(n / 1024 / 1024 / 1024).toFixed(2)} GiB (${n.toLocaleString("en-US")} bytes)`;
}

function parseE2BFile(raw: string | null): Record<string, string> {
  const out: Record<string, string> = {};
  if (!raw) return out;
  for (const line of raw.split("\n")) {
    const idx = line.indexOf("=");
    if (idx > 0) out[line.slice(0, idx).trim()] = line.slice(idx + 1).trim();
  }
  return out;
}

export function safeParseDbUrl(raw: string | undefined) {
  if (!raw) return { set: false as const };
  try {
    const u = new URL(raw);
    return {
      set: true as const,
      scheme: u.protocol.replace(/:$/, ""),
      host: u.hostname,
      port: u.port || "(default)",
      database: u.pathname.replace(/^\//, "") || null,
    };
  } catch {
    return { set: true as const, scheme: "(unparseable)", host: null, port: null, database: null };
  }
}

export type MarkerState = { path: string; exists: boolean; content: string | null };

function marker(p: string): MarkerState {
  const content = readText(p);
  return { path: p, exists: content !== null, content };
}

export async function collectFingerprint(hostHeader: string | null, protoHeader: string | null) {
  // --- e2b identity ---
  const e2bRaw = readText("/.e2b");
  const e2bFile = parseE2BFile(e2bRaw);
  const envTemplateId = process.env.E2B_TEMPLATE_ID ?? null;
  const templateId = e2bFile.TEMPLATE_ID ?? envTemplateId;

  // --- machine ---
  const cpus = os.cpus();
  const virt = sh("systemd-detect-virt 2>/dev/null") ?? "undetectable";
  const uname = sh("uname -a") ?? `${os.type()} ${os.release()} ${os.arch()}`;

  // --- cgroup limits (the /user slice, not cgroup root) ---
  const userMemMaxRaw = readText("/sys/fs/cgroup/user/memory.max");
  const rootMemMaxRaw = readText("/sys/fs/cgroup/memory.max");
  const userMemMax = userMemMaxRaw && /^\d+$/.test(userMemMaxRaw) ? Number(userMemMaxRaw) : null;

  // --- database ---
  const dbUrl = safeParseDbUrl(process.env.DATABASE_URL);
  let dbVersion: string | null = null;
  let dbCurrent: string | null = null;
  let dbError: string | null = null;
  try {
    const res = await db.execute(
      sql`select version() as v, current_database() as d, current_user as u`,
    );
    const rows = Array.isArray(res)
      ? (res as unknown as Array<Record<string, unknown>>)
      : ((res as unknown as { rows?: Array<Record<string, unknown>> }).rows ?? []);
    const row = rows[0];
    if (row) {
      dbVersion = String(row.v ?? "");
      dbCurrent = `${row.d} / ${row.u}`;
    }
  } catch (e) {
    dbError = e instanceof Error ? e.message : String(e);
  }
  const listeners5432 =
    sh("ss -tln 2>/dev/null | grep 5432 || true")?.split("\n").filter(Boolean) ?? [];

  // --- egress from a server route ---
  let egress = { reachable: false, status: null as number | null, latencyMs: null as number | null, error: null as string | null };
  try {
    const t0 = Date.now();
    const r = await fetch("https://example.com", {
      signal: AbortSignal.timeout(8000),
      cache: "no-store",
    });
    egress = { reachable: r.ok, status: r.status, latencyMs: Date.now() - t0, error: null };
  } catch (e) {
    egress.error = e instanceof Error ? e.message : String(e);
  }

  // --- persistence markers ---
  const projectMarker = marker(path.join(process.cwd(), ".persistence-marker"));
  const tmpMarker = marker("/tmp/.persistence-marker");

  return {
    generatedAt: new Date().toISOString(),
    e2b: {
      file: e2bRaw ? e2bFile : null,
      filePresent: e2bRaw !== null,
      envTemplateId,
      envSandboxId: process.env.E2B_SANDBOX_ID ?? null,
      envSandboxFlag: process.env.E2B_SANDBOX ?? null,
      eventsAddress: process.env.E2B_EVENTS_ADDRESS ?? null,
      templateId: templateId ?? null,
      referenceId: REFERENCE_TEMPLATE_ID,
      matchesReference: templateId === REFERENCE_TEMPLATE_ID,
      fileEnvConsistent:
        Boolean(e2bFile.TEMPLATE_ID) && Boolean(envTemplateId)
          ? e2bFile.TEMPLATE_ID === envTemplateId
          : null,
    },
    machine: {
      uname,
      kernel: os.release(),
      hostname: os.hostname(),
      virt,
      arch: os.arch(),
      cpuCount: cpus.length,
      cpuModel: cpus[0]?.model ?? "unknown",
      memTotalHuman: humanBytes(os.totalmem()),
      uptimeSec: Math.round(os.uptime()),
      runUser: sh("whoami") ?? "unknown",
      cwd: process.cwd(),
      node: process.version,
    },
    cgroup: {
      userMemoryMaxRaw: userMemMaxRaw ?? "(file not present)",
      userMemoryMaxHuman: userMemMax !== null ? humanBytes(userMemMax) : "max / unlimited",
      rootMemoryMaxRaw: rootMemMaxRaw ?? "(file not present)",
    },
    database: {
      ...dbUrl,
      version: dbVersion,
      current: dbCurrent,
      error: dbError,
      listeners5432,
      inSameVm: dbUrl.set && (dbUrl.host === "127.0.0.1" || dbUrl.host === "localhost" || dbUrl.host === "::1"),
    },
    egress: { target: "https://example.com", ...egress },
    preview: { host: hostHeader, proto: protoHeader },
    persistence: { projectMarker, tmpMarker },
  };
}

export type Fingerprint = Awaited<ReturnType<typeof collectFingerprint>>;
