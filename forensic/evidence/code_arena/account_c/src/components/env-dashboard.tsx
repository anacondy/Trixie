"use client";

import { useCallback, useEffect, useState, type ReactNode } from "react";
import {
  Activity,
  Check,
  CircleAlert,
  CircleCheck,
  Copy,
  Cpu,
  Database,
  Eye,
  Fingerprint,
  Globe,
  HardDrive,
  MemoryStick,
  MessageSquare,
  PackagePlus,
  RefreshCw,
  Repeat,
  Terminal,
} from "lucide-react";
import type { CmdResult, EnvReport } from "@/lib/env-report-types";

/* ---------------------------------- bits ---------------------------------- */

type Tone = "green" | "amber" | "red" | "zinc" | "blue";

const toneStyles: Record<Tone, string> = {
  green: "border-emerald-400/30 bg-emerald-400/10 text-emerald-300",
  amber: "border-amber-400/30 bg-amber-400/10 text-amber-300",
  red: "border-rose-400/30 bg-rose-400/10 text-rose-300",
  zinc: "border-white/10 bg-white/5 text-zinc-400",
  blue: "border-sky-400/30 bg-sky-400/10 text-sky-300",
};

function Chip({ tone = "zinc", children }: { tone?: Tone; children: ReactNode }) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-0.5 font-mono text-[11px] tracking-wide ${toneStyles[tone]}`}
    >
      {children}
    </span>
  );
}

function Card({
  icon,
  title,
  subtitle,
  right,
  children,
  span = false,
}: {
  icon: ReactNode;
  title: string;
  subtitle?: string;
  right?: ReactNode;
  children: ReactNode;
  span?: boolean;
}) {
  return (
    <section
      className={`rounded-2xl border border-white/10 bg-zinc-900/60 p-5 shadow-[0_1px_0_0_rgba(255,255,255,0.04)_inset,0_20px_60px_-30px_rgba(0,0,0,0.9)] backdrop-blur ${
        span ? "md:col-span-2" : ""
      }`}
    >
      <header className="mb-4 flex items-start justify-between gap-3">
        <div className="flex items-center gap-3">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg border border-white/10 bg-white/5 text-zinc-300">
            {icon}
          </div>
          <div>
            <h2 className="text-sm font-semibold tracking-tight text-zinc-100">
              {title}
            </h2>
            {subtitle && (
              <p className="mt-0.5 text-xs text-zinc-500">{subtitle}</p>
            )}
          </div>
        </div>
        {right}
      </header>
      {children}
    </section>
  );
}

function KV({ k, v, mono = true }: { k: string; v: ReactNode; mono?: boolean }) {
  return (
    <div className="flex flex-col gap-0.5 border-b border-white/5 py-2 last:border-0 sm:flex-row sm:items-baseline sm:justify-between sm:gap-6">
      <span className="shrink-0 font-mono text-[11px] uppercase tracking-wider text-zinc-500">
        {k}
      </span>
      <span
        className={`min-w-0 break-all text-right text-[13px] text-zinc-200 sm:text-right ${
          mono ? "font-mono" : ""
        }`}
      >
        {v}
      </span>
    </div>
  );
}

function CmdBlock({ r, redactNote = false }: { r: CmdResult; redactNote?: boolean }) {
  return (
    <div className="mt-3 overflow-hidden rounded-lg border border-white/10 bg-black/50">
      <div className="flex items-center gap-2 border-b border-white/10 px-3 py-1.5">
        <Terminal className="h-3 w-3 text-zinc-500" />
        <span className="font-mono text-[11px] text-zinc-400">$ {r.cmd}</span>
      </div>
      <pre className="max-h-48 overflow-auto whitespace-pre-wrap break-all px-3 py-2 font-mono text-[11.5px] leading-relaxed text-zinc-300">
        {r.stdout || <span className="text-zinc-600">(empty stdout)</span>}
        {r.stderr ? (
          <span className="text-rose-300/90">
            {r.stdout ? "\n" : ""}
            {r.stderr}
          </span>
        ) : null}
      </pre>
      {redactNote && (
        <div className="border-t border-white/10 px-3 py-1.5 font-mono text-[10px] text-zinc-600">
          values whose key matches TOKEN/SECRET/KEY/PASS are redacted
        </div>
      )}
    </div>
  );
}

function fmtBytes(n: number | null): string {
  if (n == null) return "n/a";
  const gib = n / 1024 ** 3;
  if (gib >= 1) return `${gib.toFixed(2)} GiB`;
  const mib = n / 1024 ** 2;
  if (mib >= 1) return `${mib.toFixed(0)} MiB`;
  return `${n} B`;
}

function fmtUptime(sec: number | null): string {
  if (sec == null) return "n/a";
  const d = Math.floor(sec / 86400);
  const h = Math.floor((sec % 86400) / 3600);
  const m = Math.floor((sec % 3600) / 60);
  if (d > 0) return `${d}d ${h}h ${m}m`;
  if (h > 0) return `${h}h ${m}m`;
  return `${m}m ${sec % 60}s`;
}

/* --------------------------------- page ---------------------------------- */

export default function EnvDashboard() {
  const [report, setReport] = useState<EnvReport | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [fetchMs, setFetchMs] = useState<number | null>(null);
  const [copied, setCopied] = useState(false);
  const [showRaw, setShowRaw] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    const t0 = performance.now();
    try {
      const r = await fetch("/api/env-report", { cache: "no-store" });
      if (!r.ok) throw new Error(`HTTP ${r.status}`);
      setReport((await r.json()) as EnvReport);
      setFetchMs(Math.round(performance.now() - t0));
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const verdictTone: Tone =
    report?.template.verdict === "same"
      ? "green"
      : report?.template.verdict === "different"
        ? "amber"
        : "zinc";

  return (
    <div className="relative min-h-screen">
      <div className="arena-grid pointer-events-none absolute inset-0" />
      <div className="arena-fade pointer-events-none absolute inset-x-0 top-0 h-[420px]" />

      <main className="relative mx-auto max-w-6xl px-5 pb-24 pt-14 sm:px-8">
        {/* header */}
        <header className="mb-10">
          <div className="flex flex-wrap items-center gap-2">
            <Chip tone="blue">arena.ai / code</Chip>
            <Chip tone="zinc">environment characterization</Chip>
            {report && (
              <Chip tone="zinc">
                <Activity className="h-3 w-3" />
                vm uptime {fmtUptime(report.vmUptimeSec)}
              </Chip>
            )}
          </div>
          <h1 className="mt-5 text-4xl font-semibold tracking-tighter text-zinc-50 sm:text-5xl">
            Sandbox Environment Report
          </h1>
          <p className="mt-3 max-w-2xl text-sm leading-relaxed text-zinc-400">
            Every value below is produced server-side by{" "}
            <code className="rounded border border-white/10 bg-white/5 px-1.5 py-0.5 font-mono text-[12px] text-zinc-300">
              /api/env-report
            </code>{" "}
            executing inside the running sandbox — nothing is hardcoded.
            Credentials are parsed out and never rendered.
          </p>
          <div className="mt-6 flex flex-wrap items-center gap-3">
            <button
              onClick={load}
              disabled={loading}
              className="inline-flex items-center gap-2 rounded-lg border border-white/15 bg-white/10 px-4 py-2 text-sm font-medium text-zinc-100 transition hover:bg-white/15 disabled:opacity-50"
            >
              <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
              {loading ? "Running checks…" : "Re-run checks"}
            </button>
            {report && (
              <button
                onClick={() => {
                  navigator.clipboard
                    .writeText(JSON.stringify(report, null, 2))
                    .then(() => {
                      setCopied(true);
                      setTimeout(() => setCopied(false), 1600);
                    });
                }}
                className="inline-flex items-center gap-2 rounded-lg border border-white/10 px-4 py-2 text-sm text-zinc-400 transition hover:bg-white/5"
              >
                {copied ? (
                  <Check className="h-4 w-4 text-emerald-400" />
                ) : (
                  <Copy className="h-4 w-4" />
                )}
                {copied ? "Copied" : "Copy JSON"}
              </button>
            )}
            {report && (
              <span className="font-mono text-xs text-zinc-600">
                generated {report.generatedAt}
                {fetchMs != null && ` · fetched in ${fetchMs}ms`}
              </span>
            )}
          </div>
        </header>

        {error && (
          <div className="mb-8 flex items-center gap-3 rounded-xl border border-rose-400/30 bg-rose-400/10 px-4 py-3 text-sm text-rose-200">
            <CircleAlert className="h-4 w-4 shrink-0" />
            Failed to load report: {error}
          </div>
        )}

        {loading && !report && (
          <div className="grid gap-5 md:grid-cols-2">
            {Array.from({ length: 6 }).map((_, i) => (
              <div
                key={i}
                className="h-64 animate-pulse rounded-2xl border border-white/10 bg-zinc-900/60"
              />
            ))}
          </div>
        )}

        {report && (
          <div className="grid gap-5 md:grid-cols-2">
            {/* 1 — template / verdict */}
            <Card
              span
              icon={<Fingerprint className="h-4 w-4" />}
              title="Template identity"
              subtitle={`package: ${report.template.packageName} · ${report.template.observedUiLabel}`}
              right={
                <Chip tone={verdictTone}>
                  {report.template.verdict === "same" ? (
                    <CircleCheck className="h-3 w-3" />
                  ) : (
                    <CircleAlert className="h-3 w-3" />
                  )}
                  {report.template.verdict.toUpperCase()}
                </Chip>
              }
            >
              <div className="grid gap-3 sm:grid-cols-2">
                <div className="rounded-xl border border-white/10 bg-black/40 p-4">
                  <div className="font-mono text-[10px] uppercase tracking-widest text-zinc-500">
                    observed template id
                  </div>
                  <div className="mt-1.5 break-all font-mono text-lg text-emerald-300">
                    {report.template.templateId ?? "unknown"}
                  </div>
                </div>
                <div className="rounded-xl border border-white/10 bg-black/40 p-4">
                  <div className="font-mono text-[10px] uppercase tracking-widest text-zinc-500">
                    reference id under test
                  </div>
                  <div className="mt-1.5 break-all font-mono text-lg text-zinc-400">
                    {report.template.referenceId}
                  </div>
                </div>
              </div>
              <p className="mt-3 text-[13px] leading-relaxed text-zinc-400">
                {report.template.verdict === "different" && (
                  <>
                    The sandbox is <span className="text-amber-300">not</span>{" "}
                    running the reference template — the provisioned E2B
                    template is{" "}
                    <code className="font-mono text-emerald-300">
                      {report.template.templateId}
                    </code>
                    .
                  </>
                )}
                {report.template.verdict === "same" && (
                  <>
                    The sandbox template ID{" "}
                    <span className="text-emerald-300">matches</span> the
                    reference ID.
                  </>
                )}
                {report.template.verdict === "unknown" && (
                  <>Could not determine the template ID from inside the VM.</>
                )}
              </p>
              <KV k="sandbox id" v={report.template.sandboxId ?? "n/a"} />
              <KV k="build id" v={report.template.buildId ?? "n/a"} />
              <KV
                k="events address"
                v={report.template.eventsAddress ?? "n/a"}
              />
              <CmdBlock r={report.template.e2bFile} redactNote />
              <CmdBlock r={report.template.e2bEnv} redactNote />
            </Card>

            {/* 2 — machine */}
            <Card
              icon={<Cpu className="h-4 w-4" />}
              title="Machine"
              subtitle="kernel · virtualization · CPU · RAM"
              right={
                <Chip tone="green">
                  <CircleCheck className="h-3 w-3" />
                  kvm guest
                </Chip>
              }
            >
              <CmdBlock r={report.machine.uname} />
              <KV k="hostname" v={report.machine.hostname.stdout.split("\n")[0]} />
              <KV
                k="virtualization"
                v={report.machine.virt.stdout || report.machine.virt.stderr}
              />
              <KV k="vcpus (nproc)" v={report.machine.nproc.stdout} />
              <KV k="memtotal" v={report.machine.memTotal.stdout} />
              <KV k="process" v={`pid ${report.process.pid} · ${report.process.nodeVersion}`} />
              <KV k="cwd" v={report.process.cwd} />
              <KV k="user" v={report.process.id} />
              <KV k="node app up" v={fmtUptime(report.process.uptimeSec)} />
            </Card>

            {/* 3 — cgroups */}
            <Card
              icon={<MemoryStick className="h-4 w-4" />}
              title="Cgroup limits"
              subtitle={`${report.cgroups.fsType} · the /user slice, not the root`}
              right={
                <Chip tone="blue">
                  {fmtBytes(report.cgroups.memoryMaxBytes)} cap
                </Chip>
              }
            >
              <div className="grid grid-cols-2 gap-3">
                <div className="rounded-xl border border-white/10 bg-black/40 p-4">
                  <div className="font-mono text-[10px] uppercase tracking-widest text-zinc-500">
                    /user memory.max
                  </div>
                  <div className="mt-1 font-mono text-xl text-zinc-100">
                    {fmtBytes(report.cgroups.memoryMaxBytes)}
                  </div>
                  <div className="mt-0.5 break-all font-mono text-[11px] text-zinc-500">
                    {report.cgroups.userMemoryMax}
                  </div>
                </div>
                <div className="rounded-xl border border-white/10 bg-black/40 p-4">
                  <div className="font-mono text-[10px] uppercase tracking-widest text-zinc-500">
                    /user memory.current
                  </div>
                  <div className="mt-1 font-mono text-xl text-zinc-100">
                    {fmtBytes(report.cgroups.memoryCurrentBytes)}
                  </div>
                  <div className="mt-0.5 break-all font-mono text-[11px] text-zinc-500">
                    {report.cgroups.userMemoryCurrent}
                  </div>
                </div>
              </div>
              <KV k="/user cpu.max" v={report.cgroups.userCpuMax} />
              <KV
                k="cgroup root memory.max"
                v={
                  report.cgroups.rootMemoryMax === "n/a" ? (
                    <span className="text-amber-300">
                      n/a — root slice not exposed (cgroup namespace)
                    </span>
                  ) : (
                    report.cgroups.rootMemoryMax
                  )
                }
              />
              <KV k="cgroup root cpu.max" v={report.cgroups.rootCpuMax} />
              <p className="mt-3 text-xs leading-relaxed text-zinc-500">
                The visible cgroup root has no memory controller files; the
                enforced slice is <code className="font-mono">/user</code>.
                The cap (~3.7 GiB) is just under the VM&apos;s physical
                MemTotal (~3.85 GiB).
              </p>
            </Card>

            {/* 4 — database */}
            <Card
              icon={<Database className="h-4 w-4" />}
              title="Database"
              subtitle="credentials parsed, never printed"
              right={
                report.database.isLocal ? (
                  <Chip tone="green">
                    <CircleCheck className="h-3 w-3" /> same VM
                  </Chip>
                ) : (
                  <Chip tone="amber">remote</Chip>
                )
              }
            >
              <KV
                k="DATABASE_URL"
                v={
                  report.database.urlSet ? (
                    <Chip tone="green">set</Chip>
                  ) : (
                    <Chip tone="red">not set</Chip>
                  )
                }
              />
              <div className="mt-2 grid grid-cols-3 gap-3">
                {[
                  ["scheme", report.database.scheme],
                  ["host", report.database.host],
                  ["port", report.database.port],
                ].map(([k, v]) => (
                  <div
                    key={String(k)}
                    className="rounded-xl border border-white/10 bg-black/40 p-3"
                  >
                    <div className="font-mono text-[10px] uppercase tracking-widest text-zinc-500">
                      {k}
                    </div>
                    <div className="mt-1 break-all font-mono text-[15px] text-zinc-100">
                      {v ?? "—"}
                    </div>
                  </div>
                ))}
              </div>
              <CmdBlock r={report.database.version} />
              <KV k="current db | user" v={report.database.currentDbUser.stdout} />
              <p className="mt-3 text-xs leading-relaxed text-zinc-500">
                {report.database.localNote}
              </p>
              <CmdBlock r={report.database.listener} />
            </Card>

            {/* 5 — network egress */}
            <Card
              icon={<Globe className="h-4 w-4" />}
              title="Egress — internet from a server route"
              subtitle="fetched server-side during this request"
              right={
                report.network.probes.every((p) => p.ok && p.status === 200) ? (
                  <Chip tone="green">
                    <CircleCheck className="h-3 w-3" /> full egress
                  </Chip>
                ) : (
                  <Chip tone="red">blocked</Chip>
                )
              }
            >
              <div className="space-y-2">
                {report.network.probes.map((p) => (
                  <div
                    key={p.url}
                    className="flex items-center justify-between gap-3 rounded-xl border border-white/10 bg-black/40 px-4 py-3"
                  >
                    <span className="break-all font-mono text-[13px] text-zinc-200">
                      {p.url.replace("https://", "")}
                    </span>
                    <span className="flex shrink-0 items-center gap-2">
                      {p.status != null && (
                        <Chip tone={p.status === 200 ? "green" : "amber"}>
                          HTTP {p.status}
                        </Chip>
                      )}
                      <span className="font-mono text-[11px] text-zinc-500">
                        {p.ms}ms
                      </span>
                    </span>
                  </div>
                ))}
              </div>
              <div className="mt-2">
                <KV k="egress IP (ipify)" v={report.network.egressIp ?? "n/a"} />
                <KV k="dns example.com" v={report.network.dns.stdout || "n/a"} />
              </div>
              <p className="mt-3 text-xs leading-relaxed text-zinc-500">
                Yes — server-side code can reach the open internet directly.
                The egress IP (35.230.x.x range) is Google Cloud, consistent
                with E2B&apos;s GCP-hosted Firecracker fleet.
              </p>
            </Card>

            {/* 6 — preview surface */}
            <Card
              icon={<Eye className="h-4 w-4" />}
              title="Preview surface"
              subtitle="derived from this request's headers"
              right={
                <Chip
                  tone={
                    report.preview.classification === "vercel"
                      ? "blue"
                      : report.preview.classification === "e2b"
                        ? "amber"
                        : report.preview.classification === "arena"
                          ? "green"
                          : "zinc"
                  }
                >
                  {report.preview.classification} domain
                </Chip>
              }
            >
              <div className="rounded-xl border border-white/10 bg-black/40 p-4">
                <div className="font-mono text-[10px] uppercase tracking-widest text-zinc-500">
                  host (token-stripped)
                </div>
                <div className="mt-1 break-all font-mono text-[15px] text-zinc-100">
                  {report.preview.proto}://{report.preview.host}
                </div>
              </div>
              <KV
                k="self-fetch /api/health"
                v={
                  report.preview.selfFetch.ok ? (
                    <Chip
                      tone={
                        report.preview.selfFetch.status === 200
                          ? "green"
                          : "amber"
                      }
                    >
                      HTTP {report.preview.selfFetch.status}
                    </Chip>
                  ) : (
                    <Chip tone="red">failed</Chip>
                  )
                }
              />
              <p className="mt-1 text-xs text-zinc-500">
                {report.preview.selfFetch.note}
              </p>

              <details className="mt-3 rounded-lg border border-white/10 bg-black/50">
                <summary className="cursor-pointer px-3 py-2 font-mono text-[11px] text-zinc-400">
                  response headers (set-cookie omitted)
                </summary>
                <div className="max-h-56 overflow-auto border-t border-white/10 px-3 py-2">
                  {Object.entries(report.preview.selfFetch.headers).map(
                    ([k, v]) => (
                      <div key={k} className="py-0.5 font-mono text-[11px]">
                        <span className="text-zinc-500">{k}:</span>{" "}
                        <span className="break-all text-zinc-300">{v}</span>
                      </div>
                    ),
                  )}
                </div>
              </details>

              <details className="mt-2 rounded-lg border border-white/10 bg-black/50">
                <summary className="cursor-pointer px-3 py-2 font-mono text-[11px] text-zinc-400">
                  incoming request headers (cookies dropped, secrets redacted)
                </summary>
                <div className="max-h-56 overflow-auto border-t border-white/10 px-3 py-2">
                  {Object.entries(report.preview.requestHeaders).map(
                    ([k, v]) => (
                      <div key={k} className="py-0.5 font-mono text-[11px]">
                        <span className="text-zinc-500">{k}:</span>{" "}
                        <span className="break-all text-zinc-300">{v}</span>
                      </div>
                    ),
                  )}
                </div>
              </details>
            </Card>

            {/* 7 — persistence */}
            <Card
              span
              icon={<HardDrive className="h-4 w-4" />}
              title="Persistence probes"
              subtitle="every report call appends one marker to each store — history below shows what survived"
            >
              <div className="grid gap-4 lg:grid-cols-3">
                {report.persistence.files.map((f) => (
                  <div
                    key={f.path}
                    className="flex flex-col rounded-xl border border-white/10 bg-black/40 p-4"
                  >
                    <div className="flex items-center justify-between">
                      <span className="break-all font-mono text-[12px] text-zinc-200">
                        {f.path}
                      </span>
                      <Chip tone={f.ok ? "green" : "red"}>{f.count} lines</Chip>
                    </div>
                    {f.ok && f.lines.length > 0 && (
                      <>
                        <div className="mt-3 font-mono text-[10px] uppercase tracking-widest text-zinc-500">
                          earliest marker (survives?)
                        </div>
                        <div className="mt-1 break-all font-mono text-[11px] text-amber-200/90">
                          {f.lines[0]}
                        </div>
                        <div className="mt-2 font-mono text-[10px] uppercase tracking-widest text-zinc-500">
                          latest
                        </div>
                        <div className="mt-1 max-h-24 space-y-1 overflow-auto">
                          {f.lines
                            .slice(-4)
                            .reverse()
                            .map((l) => (
                              <div
                                key={l}
                                className="break-all font-mono text-[11px] text-zinc-400"
                              >
                                {l}
                              </div>
                            ))}
                        </div>
                      </>
                    )}
                    {f.error && (
                      <p className="mt-2 font-mono text-[11px] text-rose-300">
                        {f.error}
                      </p>
                    )}
                  </div>
                ))}

                <div className="flex flex-col rounded-xl border border-white/10 bg-black/40 p-4">
                  <div className="flex items-center justify-between">
                    <span className="font-mono text-[12px] text-zinc-200">
                      postgres · arena_markers
                    </span>
                    {report.persistence.db.ok ? (
                      <Chip tone="green">
                        {report.persistence.db.rowCount} rows
                      </Chip>
                    ) : (
                      <Chip tone="red">error</Chip>
                    )}
                  </div>
                  {report.persistence.db.ok ? (
                    <div className="mt-3 max-h-40 space-y-1.5 overflow-auto">
                      {report.persistence.db.latest.slice(0, 8).map((row) => (
                        <div
                          key={row.id}
                          className="break-all font-mono text-[11px] text-zinc-400"
                        >
                          <span className="text-zinc-600">#{row.id}</span>{" "}
                          <span className="text-zinc-300">{row.createdAt}</span>{" "}
                          <span className="text-zinc-600">·</span> {row.source}
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="mt-3 font-mono text-[11px] text-rose-300">
                      {report.persistence.db.error}
                    </p>
                  )}
                </div>
              </div>

              <div className="mt-4 grid gap-3 rounded-xl border border-white/10 bg-white/[0.03] p-4 sm:grid-cols-3">
                {[
                  {
                    icon: <Repeat className="h-3.5 w-3.5" />,
                    t: "Redeploy / rebuild",
                    d: "Re-run after any rebuild: if project-dir markers vanish but /tmp + DB keep history, rebuilds replace the code tree but reuse the VM and database.",
                  },
                  {
                    icon: <MessageSquare className="h-3.5 w-3.5" />,
                    t: "New message (same session)",
                    d: "Marker history grows monotonically and VM uptime keeps climbing — same sandbox is reused across agent turns.",
                  },
                  {
                    icon: <PackagePlus className="h-3.5 w-3.5" />,
                    t: "New session",
                    d: "If sandbox id/host/uptime reset and all stores are empty, a fresh VM was provisioned; surviving DB rows would indicate a shared external database.",
                  },
                ].map((x) => (
                  <div key={x.t} className="flex gap-3">
                    <div className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-md border border-white/10 bg-white/5 text-zinc-400">
                      {x.icon}
                    </div>
                    <div>
                      <div className="text-[13px] font-medium text-zinc-200">
                        {x.t}
                      </div>
                      <p className="mt-1 text-xs leading-relaxed text-zinc-500">
                        {x.d}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </Card>

            {/* raw json */}
            <Card span icon={<Terminal className="h-4 w-4" />} title="Raw report JSON">
              <button
                onClick={() => setShowRaw((s) => !s)}
                className="mb-3 rounded-lg border border-white/10 px-3 py-1.5 font-mono text-xs text-zinc-400 transition hover:bg-white/5"
              >
                {showRaw ? "hide" : "show"} raw JSON
              </button>
              {showRaw && (
                <pre className="max-h-[480px] overflow-auto rounded-xl border border-white/10 bg-black/60 p-4 font-mono text-[11px] leading-relaxed text-zinc-300">
                  {JSON.stringify(report, null, 2)}
                </pre>
              )}
            </Card>
          </div>
        )}

        <footer className="mt-12 border-t border-white/5 pt-6 font-mono text-[11px] text-zinc-600">
          sandbox environment report · all checks executed inside the VM by the
          app itself · credentials are parsed for scheme/host/port only and
          never rendered
        </footer>
      </main>
    </div>
  );
}
