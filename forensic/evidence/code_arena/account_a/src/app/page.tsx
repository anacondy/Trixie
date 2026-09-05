import { headers } from "next/headers";
import {
  Cpu,
  Database,
  FileBadge,
  Fingerprint,
  Globe,
  History,
  MemoryStick,
  MonitorSmartphone,
  ScanLine,
  TerminalSquare,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { collectFingerprint } from "@/lib/fingerprint";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

type Row = { k: string; v: string; tone?: "ok" | "warn" | "dim" };

function Chip({ tone, children }: { tone: "ok" | "warn" | "dim"; children: string }) {
  const cls =
    tone === "ok"
      ? "border-emerald-400/40 bg-emerald-400/10 text-emerald-300"
      : tone === "warn"
        ? "border-amber-400/40 bg-amber-400/10 text-amber-300"
        : "border-zinc-700 bg-zinc-800/60 text-zinc-400";
  return (
    <span className={`inline-flex items-center rounded-full border px-2 py-0.5 text-[10px] uppercase tracking-[0.14em] ${cls}`}>
      {children}
    </span>
  );
}

function Section({
  n,
  icon: Icon,
  title,
  tone,
  chip,
  rows,
  wide = false,
}: {
  n: string;
  icon: LucideIcon;
  title: string;
  tone: "ok" | "warn" | "dim";
  chip: string;
  rows: Row[];
  wide?: boolean;
}) {
  return (
    <section
      className={`group relative overflow-hidden rounded-2xl border border-zinc-800/80 bg-zinc-900/40 p-5 transition-colors duration-300 hover:border-zinc-700 ${
        wide ? "md:col-span-2" : ""
      }`}
    >
      <div className="pointer-events-none absolute -right-6 -top-8 select-none text-[7rem] font-bold leading-none text-zinc-800/40 transition-colors duration-300 group-hover:text-zinc-800/70">
        {n}
      </div>
      <header className="relative mb-4 flex items-center justify-between gap-3">
        <div className="flex items-center gap-2.5">
          <span className="grid size-8 place-items-center rounded-lg border border-zinc-700/80 bg-zinc-900 text-zinc-300">
            <Icon className="size-4" strokeWidth={1.75} />
          </span>
          <h2 className="text-[11px] font-semibold uppercase tracking-[0.22em] text-zinc-400">
            {title}
          </h2>
        </div>
        <Chip tone={tone}>{chip}</Chip>
      </header>
      <dl className="relative space-y-2.5">
        {rows.map((r) => (
          <div key={r.k} className="grid grid-cols-[9.5rem_1fr] items-baseline gap-3">
            <dt className="truncate text-[11px] uppercase tracking-wider text-zinc-500">{r.k}</dt>
            <dd
              className={`break-all text-[13px] leading-relaxed ${
                r.tone === "ok"
                  ? "text-emerald-300"
                  : r.tone === "warn"
                    ? "text-amber-300"
                    : r.tone === "dim"
                      ? "text-zinc-500"
                      : "text-zinc-100"
              }`}
            >
              {r.v}
            </dd>
          </div>
        ))}
      </dl>
    </section>
  );
}

export default async function HomePage() {
  const h = await headers();
  const fp = await collectFingerprint(h.get("host"), h.get("x-forwarded-proto"));

  const same = fp.e2b.matchesReference;

  return (
    <main className="relative mx-auto min-h-screen w-full max-w-6xl px-5 py-10 md:px-8">
      {/* backdrop grid */}
      <div
        aria-hidden
        className="pointer-events-none fixed inset-0 opacity-[0.5]"
        style={{
          backgroundImage:
            "linear-gradient(rgba(63,63,70,0.14) 1px, transparent 1px), linear-gradient(90deg, rgba(63,63,70,0.14) 1px, transparent 1px)",
          backgroundSize: "56px 56px",
          maskImage: "radial-gradient(ellipse 90% 60% at 50% 0%, black 30%, transparent 75%)",
        }}
      />

      {/* top bar */}
      <div className="relative mb-10 flex flex-wrap items-center justify-between gap-3 border-b border-zinc-800/80 pb-4">
        <div className="flex items-center gap-3">
          <span className="grid size-9 place-items-center rounded-lg border border-zinc-700 bg-zinc-900">
            <ScanLine className="size-4.5 text-emerald-300" strokeWidth={1.75} />
          </span>
          <div>
            <p className="text-[11px] uppercase tracking-[0.3em] text-zinc-500">Field report</p>
            <p className="text-sm font-semibold text-zinc-100">SANDBOX&nbsp;/&nbsp;ENVIRONMENT FINGERPRINT</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <span className="fp-blink inline-block size-1.5 rounded-full bg-emerald-400" />
          <span className="text-[11px] uppercase tracking-[0.18em] text-zinc-500">
            captured {fp.generatedAt.replace("T", " ").slice(0, 19)}Z
          </span>
        </div>
      </div>

      {/* verdict hero */}
      <section className="relative mb-10 overflow-hidden rounded-3xl border border-zinc-800 bg-gradient-to-b from-zinc-900/70 to-zinc-950 p-7 md:p-10">
        <p className="mb-3 flex items-center gap-2 text-[11px] uppercase tracking-[0.3em] text-zinc-500">
          <Fingerprint className="size-4" strokeWidth={1.75} />
          Q1 — the key question
        </p>
        <h1 className="text-balance text-[clamp(1.8rem,4.5vw,3.1rem)] font-semibold leading-[1.08] text-zinc-50">
          Template observed in this sandbox is{" "}
          <span className={same ? "text-emerald-300" : "text-amber-300"}>
            {same ? "identical to" : "different from"}
          </span>{" "}
          the reference ID.
        </h1>
        <div className="mt-7 grid gap-3 md:grid-cols-[1fr_auto_1fr] md:items-center">
          <div className="rounded-xl border border-emerald-400/25 bg-emerald-400/5 p-4">
            <p className="mb-1 text-[10px] uppercase tracking-[0.22em] text-emerald-300/80">
              Observed — /.e2b &amp; $E2B_TEMPLATE_ID
            </p>
            <p className="break-all font-semibold text-emerald-200">{fp.e2b.templateId ?? "(unavailable)"}</p>
          </div>
          <div className="text-center text-3xl font-bold text-zinc-600">{same ? "=" : "≠"}</div>
          <div className="rounded-xl border border-zinc-700/70 bg-zinc-900/60 p-4">
            <p className="mb-1 text-[10px] uppercase tracking-[0.22em] text-zinc-500">
              Reference under test
            </p>
            <p className="break-all text-zinc-400 line-through decoration-zinc-600">
              {fp.e2b.referenceId}
            </p>
          </div>
        </div>
        <p className="mt-5 text-[12px] leading-relaxed text-zinc-500">
          /.e2b {fp.e2b.filePresent ? "present" : "missing"}
          {fp.e2b.fileEnvConsistent !== null &&
            ` · file and env var ${fp.e2b.fileEnvConsistent ? "agree" : "DISAGREE"}`}{" "}
          · BUILD_ID {fp.e2b.file?.BUILD_ID ?? "n/a"} · sandbox {fp.e2b.envSandboxId ?? "n/a"}
        </p>
      </section>

      {/* sections */}
      <div className="relative grid gap-4 md:grid-cols-2">
        <Section
          n="02"
          icon={Cpu}
          title="Machine"
          tone="ok"
          chip="kvm guest"
          rows={[
            { k: "uname", v: fp.machine.uname },
            { k: "hostname", v: fp.machine.hostname },
            { k: "virtualization", v: fp.machine.virt, tone: "ok" },
            { k: "vCPUs", v: `${fp.machine.cpuCount} × ${fp.machine.cpuModel}` },
            { k: "MemTotal", v: fp.machine.memTotalHuman },
            { k: "run user / cwd", v: `${fp.machine.runUser} · ${fp.machine.cwd}` },
          ]}
        />
        <Section
          n="03"
          icon={MemoryStick}
          title="Cgroup memory cap"
          tone="warn"
          chip="/user slice"
          rows={[
            { k: "/user/memory.max", v: fp.cgroup.userMemoryMaxHuman, tone: "warn" },
            { k: "raw value", v: fp.cgroup.userMemoryMaxRaw, tone: "dim" },
            { k: "cgroup root", v: fp.cgroup.rootMemoryMaxRaw, tone: "dim" },
            { k: "note", v: "limit lives on the /user slice, not the cgroup root", tone: "dim" },
          ]}
        />
        <Section
          n="04"
          icon={Database}
          title="Database"
          tone="ok"
          chip={fp.database.inSameVm ? "same vm" : "remote"}
          rows={[
            {
              k: "DATABASE_URL",
              v: fp.database.set
                ? `set — ${fp.database.scheme}://${fp.database.host}:${fp.database.port}/${fp.database.database}`
                : "not set",
              tone: fp.database.set ? "ok" : "warn",
            },
            { k: "credentials", v: "redacted — scheme/host/port/db only", tone: "dim" },
            { k: "version", v: fp.database.version ?? fp.database.error ?? "query failed" },
            { k: "db / user", v: fp.database.current ?? "n/a" },
            { k: ":5432 listeners", v: fp.database.listeners5432.join("  ·  ") || "none" },
          ]}
          wide
        />
        <Section
          n="05"
          icon={Globe}
          title="Egress from server"
          tone={fp.egress.reachable ? "ok" : "warn"}
          chip={fp.egress.reachable ? "open" : "blocked"}
          rows={[
            { k: "target", v: fp.egress.target },
            {
              k: "result",
              v: fp.egress.error
                ? `failed — ${fp.egress.error}`
                : `HTTP ${fp.egress.status} in ${fp.egress.latencyMs} ms from a server route`,
              tone: fp.egress.reachable ? "ok" : "warn",
            },
          ]}
        />
        <Section
          n="06"
          icon={MonitorSmartphone}
          title="Preview surface"
          tone="dim"
          chip="as served"
          rows={[
            { k: "host header", v: fp.preview.host ?? "unknown" },
            { k: "protocol", v: fp.preview.proto ?? "unknown" },
            { k: "events addr", v: fp.e2b.eventsAddress ?? "n/a", tone: "dim" },
            { k: "note", v: "Host header reflects exactly how this page reached you", tone: "dim" },
          ]}
        />
        <Section
          n="07"
          icon={History}
          title="Persistence markers"
          tone={fp.persistence.projectMarker.exists ? "ok" : "dim"}
          chip={fp.persistence.projectMarker.exists ? "marker found" : "no marker yet"}
          rows={[
            {
              k: "project dir",
              v: fp.persistence.projectMarker.exists
                ? fp.persistence.projectMarker.content ?? "exists"
                : `${fp.persistence.projectMarker.path} — not written yet`,
              tone: fp.persistence.projectMarker.exists ? "ok" : "dim",
            },
            {
              k: "/tmp",
              v: fp.persistence.tmpMarker.exists
                ? fp.persistence.tmpMarker.content ?? "exists"
                : `${fp.persistence.tmpMarker.path} — not written yet`,
              tone: fp.persistence.tmpMarker.exists ? "ok" : "dim",
            },
            {
              k: "meaning",
              v: "if present and older than this page render, the fs survived the app restart",
              tone: "dim",
            },
          ]}
          wide
        />
        <Section
          n="08"
          icon={FileBadge}
          title="Raw /.e2b"
          tone="dim"
          chip="verbatim"
          rows={
            fp.e2b.file
              ? Object.entries(fp.e2b.file).map(([k, v]) => ({ k, v }))
              : [{ k: "/.e2b", v: "file not present in this container", tone: "warn" as const }]
          }
        />
        <Section
          n="09"
          icon={TerminalSquare}
          title="Runtime"
          tone="dim"
          chip="node"
          rows={[
            { k: "node", v: fp.machine.node },
            { k: "uptime", v: `${fp.machine.uptimeSec}s` },
            { k: "sandbox flag", v: `E2B_SANDBOX=${fp.e2b.envSandboxFlag ?? "unset"}` },
            { k: "json", v: "full report at /api/env", tone: "ok" },
          ]}
        />
      </div>

      <footer className="relative mt-10 border-t border-zinc-800/80 pt-4 text-[11px] leading-relaxed text-zinc-600">
        Generated server-side on every request from within the sandbox. No credentials are exposed by
        this page or by /api/env — the database URL is reported as scheme, host, port and database
        name only. Redeploy the app to re-test the persistence markers below the fold.
      </footer>
    </main>
  );
}
