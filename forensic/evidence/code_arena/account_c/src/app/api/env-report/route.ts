import { exec } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { promisify } from "node:util";
import { desc, sql } from "drizzle-orm";
import { db } from "@/db";
import { arenaMarkers } from "@/db/schema";
import type {
  CmdResult,
  EgressProbe,
  EnvReport,
  MarkerFileReport,
} from "@/lib/env-report-types";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

const REFERENCE_TEMPLATE_ID = "nlhz8vlwyupq845jsdg9";
const SENSITIVE =
  /(TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIAL|PRIVATE[_-]?KEY|API[_-]?KEY)/i;

const execAsync = promisify(exec);

async function run(cmd: string, timeoutMs = 15000): Promise<CmdResult> {
  try {
    const { stdout, stderr } = await execAsync(cmd, {
      timeout: timeoutMs,
      maxBuffer: 1024 * 1024,
    });
    return { cmd, ok: true, stdout: stdout.trim(), stderr: stderr.trim() };
  } catch (err) {
    const e = err as {
      stdout?: string;
      stderr?: string;
      message?: string;
      code?: number | string;
    };
    return {
      cmd,
      ok: false,
      stdout: (e.stdout ?? "").trim(),
      stderr: (
        e.stderr ||
        e.message ||
        `exit code ${e.code ?? "?"}`
      ).trim(),
    };
  }
}

/** Redact KEY=value / "key":"value" lines whose key name looks sensitive. */
function redact(text: string): string {
  return text
    .split("\n")
    .map((line) => {
      const m = line.match(/^(\s*"?[A-Za-z0-9_.\-]+"?)(\s*[:=]\s*)(.*)$/);
      if (m && SENSITIVE.test(m[1])) return `${m[1]}${m[2]}<redacted>`;
      return line;
    })
    .join("\n");
}

function readFileSafe(p: string): string {
  try {
    return fs.readFileSync(p, "utf8").trim() || "n/a";
  } catch {
    return "n/a";
  }
}

function parseBytes(v: string): number | null {
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

async function probe(url: string): Promise<EgressProbe> {
  const t0 = Date.now();
  try {
    const r = await fetch(url, {
      signal: AbortSignal.timeout(8000),
      cache: "no-store",
      redirect: "follow",
    });
    // Drain a tiny bit so the connection completes cleanly, then discard.
    await r.arrayBuffer().catch(() => undefined);
    return { url, ok: true, status: r.status, ms: Date.now() - t0 };
  } catch (e) {
    return { url, ok: false, status: null, ms: Date.now() - t0, error: String(e) };
  }
}

async function probeText(url: string): Promise<string | null> {
  try {
    const r = await fetch(url, { signal: AbortSignal.timeout(8000), cache: "no-store" });
    if (!r.ok) return null;
    return (await r.text()).trim().slice(0, 64);
  } catch {
    return null;
  }
}

function touchMarkerFile(p: string, line: string): MarkerFileReport {
  try {
    fs.appendFileSync(p, line + "\n");
    const lines = fs
      .readFileSync(p, "utf8")
      .split("\n")
      .map((l) => l.trim())
      .filter(Boolean);
    return { path: p, ok: true, count: lines.length, lines: lines.slice(-50) };
  } catch (e) {
    return { path: p, ok: false, count: 0, lines: [], error: String(e) };
  }
}

function classifyHost(host: string): EnvReport["preview"]["classification"] {
  const h = host.toLowerCase();
  if (/^(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])(:\d+)?$/.test(h)) return "localhost";
  if (/\.e2b\.(app|dev|land|io)$/.test(h) || /(^|[.-])e2b([.-]|$)/.test(h)) return "e2b";
  if (/arena/i.test(h)) return "arena";
  if (/\.vercel\.(app|dev)$/.test(h)) return "vercel";
  return "other";
}

export async function GET(req: Request) {
  const generatedAt = new Date().toISOString();
  const nowMarker = crypto.randomUUID();

  // ---------- template / identity ----------
  let packageName = "unknown";
  try {
    packageName =
      JSON.parse(fs.readFileSync(path.join(process.cwd(), "package.json"), "utf8"))
        .name ?? "unknown";
  } catch {
    /* ignore */
  }

  const e2bFileRaw = await run("cat /.e2b 2>/dev/null || echo '__missing__'");
  const e2bEnvRaw = await run("env | grep '^E2B_' | sort || true");
  const e2bFile: CmdResult = { ...e2bFileRaw, stdout: redact(e2bFileRaw.stdout) };
  const e2bEnv: CmdResult = { ...e2bEnvRaw, stdout: redact(e2bEnvRaw.stdout) };

  const grab = (text: string, key: string): string | null => {
    const m = text.match(new RegExp(`^${key}=(\\S+)`, "m"));
    return m ? m[1] : null;
  };
  const templateId =
    grab(e2bFile.stdout, "TEMPLATE_ID") ??
    grab(e2bEnv.stdout, "E2B_TEMPLATE_ID");
  const buildId = grab(e2bFile.stdout, "BUILD_ID");
  const sandboxId = grab(e2bEnv.stdout, "E2B_SANDBOX_ID");
  const eventsAddress = grab(e2bEnv.stdout, "E2B_EVENTS_ADDRESS");
  const verdict: EnvReport["template"]["verdict"] =
    templateId == null
      ? "unknown"
      : templateId === REFERENCE_TEMPLATE_ID
        ? "same"
        : "different";

  // ---------- machine ----------
  const [uname, hostname, virt, nproc, memTotal, idCmd, cgroupFs] =
    await Promise.all([
      run("uname -a"),
      run("hostname; cat /etc/hostname 2>/dev/null || true"),
      run("systemd-detect-virt 2>&1"),
      run("nproc"),
      run("grep MemTotal /proc/meminfo"),
      run("id"),
      run("stat -fc %T /sys/fs/cgroup 2>/dev/null || echo n/a"),
    ]);

  const cgroups: EnvReport["cgroups"] = {
    fsType: cgroupFs.stdout || "n/a",
    rootMemoryMax: readFileSafe("/sys/fs/cgroup/memory.max"),
    rootMemoryCurrent: readFileSafe("/sys/fs/cgroup/memory.current"),
    rootCpuMax: readFileSafe("/sys/fs/cgroup/cpu.max"),
    userMemoryMax: readFileSafe("/sys/fs/cgroup/user/memory.max"),
    userMemoryCurrent: readFileSafe("/sys/fs/cgroup/user/memory.current"),
    userCpuMax: readFileSafe("/sys/fs/cgroup/user/cpu.max"),
    memoryMaxBytes: null,
    memoryCurrentBytes: null,
  };
  cgroups.memoryMaxBytes = parseBytes(cgroups.userMemoryMax);
  cgroups.memoryCurrentBytes = parseBytes(cgroups.userMemoryCurrent);

  let vmUptimeSec: number | null = null;
  try {
    vmUptimeSec = Math.floor(
      Number(fs.readFileSync("/proc/uptime", "utf8").split(" ")[0]),
    );
  } catch {
    /* ignore */
  }

  // ---------- database (never expose credentials) ----------
  let dbScheme: string | null = null;
  let dbHost: string | null = null;
  let dbPort: string | null = null;
  const dbUrl = process.env.DATABASE_URL;
  if (dbUrl) {
    try {
      const u = new URL(dbUrl);
      dbScheme = u.protocol.replace(/:$/, "");
      dbHost = u.hostname;
      dbPort = u.port || null;
    } catch {
      /* leave null */
    }
  }
  const [dbVersion, dbCurrent, dbListener] = await Promise.all([
    run(`psql "$DATABASE_URL" -tA -c 'select version();'`, 20000),
    run(
      `psql "$DATABASE_URL" -tA -c 'select current_database(), current_user;'`,
      20000,
    ),
    run("(sudo -n ss -tlnp 2>/dev/null || ss -tlnp) | grep 5432 || echo 'nothing on :5432'"),
  ]);
  const isLocal =
    /127\.0\.0\.1:5432/.test(dbListener.stdout) ||
    /\[::1\]:5432/.test(dbListener.stdout);

  // ---------- network egress ----------
  const [probeExample, probeNpm, egressIp, dns] = await Promise.all([
    probe("https://example.com"),
    probe("https://registry.npmjs.org"),
    probeText("https://api.ipify.org"),
    run("getent hosts example.com | head -1 || true"),
  ]);

  // ---------- preview surface (from this very request) ----------
  const rawHost = req.headers.get("host") ?? "unknown";
  const host = rawHost.split(/[/?#]/)[0];
  const proto =
    req.headers.get("x-forwarded-proto") ??
    (classifyHost(host) === "localhost" ? "http" : "https");
  const requestHeaders: Record<string, string> = {};
  req.headers.forEach((value, key) => {
    if (key === "cookie") return; // never echo cookies
    requestHeaders[key] = SENSITIVE.test(key) ? "<redacted>" : value;
  });

  const selfUrl = `${proto}://${host}/api/health`;
  const selfFetch: EnvReport["preview"]["selfFetch"] = {
    ok: false,
    url: selfUrl,
    status: null,
    note: "",
    headers: {},
  };
  try {
    const r = await fetch(selfUrl, {
      redirect: "manual",
      cache: "no-store",
      signal: AbortSignal.timeout(6000),
    });
    selfFetch.ok = true;
    selfFetch.status = r.status;
    r.headers.forEach((value, key) => {
      const k = key.toLowerCase();
      if (k === "set-cookie") {
        selfFetch.headers[k] = "<omitted>";
        return;
      }
      if (k === "location") {
        try {
          const loc = new URL(value, selfUrl);
          selfFetch.headers[k] = `${loc.host}/…?… (path/query stripped)`;
          return;
        } catch {
          /* fall through */
        }
      }
      selfFetch.headers[k] = value;
    });
    selfFetch.note =
      r.status >= 300 && r.status < 400
        ? "redirected (likely an auth/access guard in front of the preview)"
        : r.status === 401 || r.status === 403
          ? "blocked by an access layer (status is informative by itself)"
          : "reachable directly from inside the sandbox";
  } catch (e) {
    selfFetch.note = `self-request failed from inside the sandbox: ${String(e).slice(0, 200)}`;
  }

  // ---------- persistence probes ----------
  const markerLine = `${generatedAt} ${nowMarker} pid=${process.pid}`;
  const files = [
    touchMarkerFile(path.join(process.cwd(), ".arena-marker.log"), markerLine),
    touchMarkerFile("/tmp/arena-marker.log", markerLine),
  ];

  let dbReport: EnvReport["persistence"]["db"];
  try {
    await db
      .insert(arenaMarkers)
      .values({ marker: nowMarker, source: "api/env-report" });
    const rows = await db
      .select()
      .from(arenaMarkers)
      .orderBy(desc(arenaMarkers.createdAt))
      .limit(50);
    const countRes = await db.execute<{ count: number }>(
      sql`select count(*)::int as count from arena_markers`,
    );
    dbReport = {
      ok: true,
      rowCount: countRes.rows[0]?.count ?? rows.length,
      latest: rows.map((r) => ({
        id: r.id,
        marker: r.marker,
        source: r.source,
        createdAt: String(r.createdAt),
      })),
    };
  } catch (e) {
    dbReport = {
      ok: false,
      rowCount: null,
      latest: [],
      error: String(e).slice(0, 300),
    };
  }

  const report: EnvReport = {
    generatedAt,
    vmUptimeSec,
    process: {
      nodeVersion: process.version,
      pid: process.pid,
      cwd: process.cwd(),
      uptimeSec: Math.round(process.uptime()),
      startedAt: new Date(Date.now() - process.uptime() * 1000).toISOString(),
      id: idCmd.stdout,
    },
    template: {
      packageName,
      observedUiLabel: "Arena Next.js PostgreSQL Starter (from layout.tsx metadata)",
      e2bFile,
      e2bEnv,
      templateId,
      buildId,
      sandboxId,
      eventsAddress,
      referenceId: REFERENCE_TEMPLATE_ID,
      verdict,
    },
    machine: { uname, hostname, virt, nproc, memTotal },
    cgroups,
    database: {
      urlSet: Boolean(dbUrl),
      scheme: dbScheme,
      host: dbHost,
      port: dbPort,
      version: dbVersion,
      currentDbUser: dbCurrent,
      listener: dbListener,
      isLocal,
      localNote: isLocal
        ? "PostgreSQL is listening on loopback/firewall-local addresses — it runs inside the same VM as the app (plus a socat forwarder on 169.254.0.21)."
        : "No local :5432 listener found — the database appears to be remote.",
    },
    network: {
      probes: [probeExample, probeNpm],
      egressIp,
      dns,
    },
    preview: {
      host,
      proto,
      classification: classifyHost(host),
      requestHeaders,
      selfFetch,
    },
    persistence: {
      nowMarker,
      files,
      db: dbReport,
    },
  };

  return Response.json(report);
}
