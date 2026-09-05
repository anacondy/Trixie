import { execSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { headers } from "next/headers";
import { db } from "@/db";
import { sql } from "drizzle-orm";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

/** Template id the environment "should" have been, per the recon brief. */
const EXPECTED_TEMPLATE_ID = "nlhz8vlwyupq845jsdg9";

function run(cmd: string): string {
  try {
    return execSync(cmd, {
      encoding: "utf8",
      timeout: 8_000,
      stdio: ["ignore", "pipe", "pipe"],
    }).trim();
  } catch {
    return "(unavailable)";
  }
}

function readSafe(path: string): string {
  try {
    return readFileSync(path, "utf8").trim();
  } catch {
    return "(missing)";
  }
}

/** Parse DATABASE_URL exposing scheme/host/port/db ONLY — never credentials. */
function redactedDbInfo() {
  const raw = process.env.DATABASE_URL;
  if (!raw) return { set: false as const };
  try {
    const u = new URL(raw);
    return {
      set: true as const,
      scheme: u.protocol.replace(/:$/, ""),
      host: u.hostname,
      port: u.port || "(default)",
      database: u.pathname.replace(/^\//, ""),
      credentials: "[redacted — userinfo intentionally never serialized]",
    };
  } catch {
    return { set: true as const, parseError: true };
  }
}

export async function GET() {
  const started = Date.now();

  // ---- machine probes (same commands as the brief) ----
  const uname = run("uname -a");
  const hostname = run("hostname");
  const virt = run("systemd-detect-virt");
  const nproc = run("nproc");
  const memTotal = run("grep MemTotal /proc/meminfo");
  const cgroupUserMax = readSafe("/sys/fs/cgroup/user/memory.max");
  const selfCgroup = readSafe("/proc/self/cgroup");
  const dotE2b = readSafe("/.e2b");

  const e2bEnv = Object.fromEntries(
    Object.entries(process.env)
      .filter(([k]) => k.startsWith("E2B_"))
      .sort(([a], [b]) => a.localeCompare(b)),
  );

  // ---- database probes (via the app's own Drizzle client) ----
  let dbVersion = "(query failed)";
  let dbIdentity = "(query failed)";
  let dbRoundTripMs = -1;
  try {
    const t0 = Date.now();
    const v = await db.execute(sql`select version() as version`);
    const i = await db.execute(
      sql`select current_database() as db, current_user as usr`,
    );
    dbRoundTripMs = Date.now() - t0;
    dbVersion = String((v.rows[0] as { version: string }).version);
    const row = i.rows[0] as { db: string; usr: string };
    dbIdentity = `${row.usr}@${row.db}`;
  } catch {
    /* leave fallbacks */
  }
  const pgIsLocal = run("ss -tln 2>/dev/null | grep -c ':5432'");

  // ---- egress probe from a server route ----
  let egress: Record<string, unknown> = { reachable: false };
  try {
    const t0 = Date.now();
    const res = await fetch("https://api.github.com", {
      signal: AbortSignal.timeout(8_000),
      cache: "no-store",
    });
    egress = {
      reachable: res.ok,
      status: res.status,
      url: "https://api.github.com",
      latencyMs: Date.now() - t0,
    };
  } catch {
    egress = { reachable: false, url: "https://api.github.com" };
  }

  // ---- headers the server actually saw on THIS request (tokens redacted) ----
  const h = await headers();
  const seenHeaders: Record<string, string> = {};
  for (const [k, v] of h.entries()) {
    seenHeaders[k] = /token|cookie|authorization|secret|key/i.test(k)
      ? "[redacted]"
      : v;
  }

  // ---- persistence probe: was an agent-written file visible to the server? ----
  const markerPath = "sandbox-recon-marker.txt";
  const marker = existsSync(markerPath) ? readSafe(markerPath) : null;

  return Response.json({
    ok: true,
    generatedAt: new Date().toISOString(),
    probeDurationMs: Date.now() - started,
    template: {
      packageName: "nextjs-postgresql-template",
      scaffoldLabel: "Arena Next.js PostgreSQL Starter",
      expectedTemplateId: EXPECTED_TEMPLATE_ID,
      actualTemplateId: process.env.E2B_TEMPLATE_ID ?? "(unset)",
      match: process.env.E2B_TEMPLATE_ID === EXPECTED_TEMPLATE_ID,
    },
    machine: {
      uname,
      hostname,
      virtualization: virt,
      cpus: nproc,
      memTotal,
      cgroupUserMemoryMax: cgroupUserMax,
      selfCgroup,
      node: process.version,
      next: process.env.npm_package_dependencies_next ?? "16.x",
      uptimeSec: Math.floor(process.uptime()),
    },
    e2b: {
      dotE2b,
      env: e2bEnv,
    },
    database: {
      url: redactedDbInfo(),
      version: dbVersion,
      identity: dbIdentity,
      roundTripMs: dbRoundTripMs,
      listenersOn5432: pgIsLocal,
      sameVm: !pgIsLocal.startsWith("(") && Number(pgIsLocal) > 0,
    },
    network: {
      egress,
    },
    previewSurface: {
      headersSeenByServer: seenHeaders,
    },
    persistence: {
      markerFile: markerPath,
      found: marker !== null,
      contents: marker,
    },
  });
}
