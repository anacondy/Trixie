"use client";

import { useEffect, useState, type ReactNode } from "react";
import {
  Activity,
  Cpu,
  Database,
  FileClock,
  Fingerprint,
  Globe,
  MemoryStick,
  Radio,
  ShieldAlert,
  ShieldCheck,
  TerminalSquare,
} from "lucide-react";

type Recon = {
  ok: boolean;
  generatedAt: string;
  probeDurationMs: number;
  template: {
    packageName: string;
    scaffoldLabel: string;
    expectedTemplateId: string;
    actualTemplateId: string;
    match: boolean;
  };
  machine: {
    uname: string;
    hostname: string;
    virtualization: string;
    cpus: string;
    memTotal: string;
    cgroupUserMemoryMax: string;
    selfCgroup: string;
    node: string;
    next: string;
    uptimeSec: number;
  };
  e2b: { dotE2b: string; env: Record<string, string> };
  database: {
    url:
      | { set: false }
      | {
          set: true;
          scheme?: string;
          host?: string;
          port?: string;
          database?: string;
          credentials?: string;
          parseError?: boolean;
        };
    version: string;
    identity: string;
    roundTripMs: number;
    listenersOn5432: string;
    sameVm: boolean;
  };
  network: {
    egress: {
      reachable?: boolean;
      status?: number;
      url?: string;
      latencyMs?: number;
    };
  };
  previewSurface: { headersSeenByServer: Record<string, string> };
  persistence: { markerFile: string; found: boolean; contents: string | null };
};

function gib(bytes: number) {
  return (bytes / 1024 ** 3).toFixed(2);
}

function Card({
  icon,
  title,
  index,
  children,
  span = false,
}: {
  icon: ReactNode;
  title: string;
  index: string;
  children: ReactNode;
  span?: boolean;
}) {
  return (
    <section
      className={`group relative overflow-hidden rounded-xl border border-[rgba(52,245,162,0.14)] bg-[#0a0d0c]/90 p-5 shadow-[inset_0_1px_0_rgba(215,245,227,0.04)] transition-colors duration-300 hover:border-[rgba(52,245,162,0.35)] ${
        span ? "lg:col-span-2" : ""
      }`}
    >
      <header className="mb-4 flex items-center gap-2.5">
        <span className="text-[#34f5a2]">{icon}</span>
        <h2 className="text-[11px] font-semibold uppercase tracking-[0.22em] text-[#d7f5e3]">
          {title}
        </h2>
        <span className="ml-auto text-[10px] tracking-[0.3em] text-[#41524a]">
          {index}
        </span>
      </header>
      {children}
    </section>
  );
}

function Row({
  k,
  v,
  accent = false,
  warn = false,
}: {
  k: string;
  v: ReactNode;
  accent?: boolean;
  warn?: boolean;
}) {
  return (
    <div className="grid grid-cols-[minmax(110px,38%)_1fr] items-baseline gap-3 border-b border-[rgba(52,245,162,0.07)] py-1.5 last:border-none">
      <span className="text-[10px] uppercase tracking-[0.18em] text-[#5f7268]">
        {k}
      </span>
      <span
        className={`break-all text-[12.5px] leading-relaxed ${
          accent ? "text-[#34f5a2]" : warn ? "text-[#f5b434]" : "text-[#d7f5e3]"
        }`}
      >
        {v}
      </span>
    </div>
  );
}

export default function ReconPage() {
  const [data, setData] = useState<Recon | null>(null);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/env", { cache: "no-store" })
      .then((r) => r.json())
      .then(setData)
      .catch((e) => setErr(String(e)));
  }, []);

  return (
    <main className="relative min-h-screen overflow-hidden">
      <div className="recon-grid pointer-events-none absolute inset-0" />
      <div className="scanline pointer-events-none absolute inset-x-0 top-0 h-40" />

      <div className="relative mx-auto w-full max-w-5xl px-5 pb-16 pt-10 sm:px-8">
        {/* ---------- header ---------- */}
        <header className="mb-8 border-b border-[rgba(52,245,162,0.14)] pb-6">
          <div className="mb-3 flex flex-wrap items-center gap-3">
            <span className="pulse-dot inline-block h-2 w-2 rounded-full bg-[#34f5a2]" />
            <span className="text-[10px] uppercase tracking-[0.3em] text-[#5f7268]">
              live telemetry from inside the sandbox
            </span>
            {data && (
              <span className="ml-auto text-[10px] tracking-[0.2em] text-[#41524a]">
                {data.generatedAt}Z · probed in {data.probeDurationMs}ms
              </span>
            )}
          </div>
          <h1 className="text-[clamp(1.9rem,5vw,3.2rem)] font-bold leading-none tracking-tight text-[#eafff3]">
            SANDBOX<span className="text-[#34f5a2]">://</span>RECON
          </h1>
          <p className="mt-2 max-w-xl text-[12px] leading-relaxed text-[#5f7268]">
            Every value below is produced live by{" "}
            <span className="text-[#34f5a2]">GET /api/env</span> — a Next.js
            server route executing probes inside the same VM that serves this
            page.
          </p>
        </header>

        {/* ---------- states ---------- */}
        {err && (
          <p className="rounded-lg border border-[rgba(255,93,93,0.4)] p-4 text-[12px] text-[#ff5d5d]">
            probe failed: {err}
          </p>
        )}
        {!data && !err && (
          <p className="animate-pulse text-[12px] tracking-[0.25em] text-[#34f5a2]">
            &gt; probing environment_
          </p>
        )}

        {data && (
          <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
            {/* ---------- verdict ---------- */}
            <section
              className={`lg:col-span-2 rounded-xl border p-5 ${
                data.template.match
                  ? "border-[rgba(52,245,162,0.4)] bg-[rgba(52,245,162,0.05)]"
                  : "border-[rgba(245,180,52,0.45)] bg-[rgba(245,180,52,0.05)]"
              }`}
            >
              <header className="mb-4 flex items-center gap-2.5">
                {data.template.match ? (
                  <ShieldCheck size={16} className="text-[#34f5a2]" />
                ) : (
                  <ShieldAlert size={16} className="text-[#f5b434]" />
                )}
                <h2 className="text-[11px] font-semibold uppercase tracking-[0.22em]">
                  Template identity verdict
                </h2>
                <span
                  className={`ml-auto rounded px-2 py-0.5 text-[10px] font-bold tracking-[0.2em] ${
                    data.template.match
                      ? "bg-[rgba(52,245,162,0.15)] text-[#34f5a2]"
                      : "bg-[rgba(245,180,52,0.15)] text-[#f5b434]"
                  }`}
                >
                  {data.template.match ? "MATCH" : "DIFFERENT TEMPLATE"}
                </span>
              </header>
              <Row k="scaffold label" v={data.template.scaffoldLabel} />
              <Row k="package name" v={data.template.packageName} />
              <Row k="expected id" v={data.template.expectedTemplateId} warn />
              <Row
                k="actual id"
                v={data.template.actualTemplateId}
                accent={!data.template.match}
              />
            </section>

            {/* ---------- machine ---------- */}
            <Card icon={<Cpu size={15} />} title="Machine / kernel" index="02">
              <Row k="uname" v={data.machine.uname} />
              <Row k="hostname" v={data.machine.hostname} accent />
              <Row k="virtualization" v={data.machine.virtualization} />
              <Row k="vcpus" v={data.machine.cpus} />
              <Row k="memtotal" v={data.machine.memTotal} />
              <Row
                k="cgroup /user max"
                v={`${data.machine.cgroupUserMemoryMax} B${
                  /^\d+$/.test(data.machine.cgroupUserMemoryMax)
                    ? ` ≈ ${gib(Number(data.machine.cgroupUserMemoryMax))} GiB`
                    : ""
                }`}
                accent
              />
              <Row k="self cgroup" v={data.machine.selfCgroup} />
              <Row
                k="runtime"
                v={`node ${data.machine.node} · up ${data.machine.uptimeSec}s`}
              />
            </Card>

            {/* ---------- e2b identity ---------- */}
            <Card
              icon={<Fingerprint size={15} />}
              title="e2b identity"
              index="03"
            >
              {data.e2b.dotE2b
                .split("\n")
                .filter(Boolean)
                .map((line) => {
                  const [k, v] = line.split("=");
                  return <Row key={k} k={`/.e2b ${k}`} v={v} accent={k === "TEMPLATE_ID"} />;
                })}
              {Object.entries(data.e2b.env).map(([k, v]) => (
                <Row key={k} k={k} v={v} />
              ))}
              {Object.keys(data.e2b.env).length === 0 && (
                <Row k="E2B_*" v="(none set)" warn />
              )}
            </Card>

            {/* ---------- database ---------- */}
            <Card icon={<Database size={15} />} title="database" index="04">
              {data.database.url.set ? (
                <>
                  <Row
                    k="scheme://host"
                    v={`${data.database.url.scheme}://${data.database.url.host}:${data.database.url.port}`}
                    accent
                  />
                  <Row k="database" v={data.database.url.database} />
                  <Row k="credentials" v={data.database.url.credentials} warn />
                </>
              ) : (
                <Row k="DATABASE_URL" v="not set in server process" warn />
              )}
              <Row k="server" v={data.database.version} />
              <Row k="session" v={data.database.identity} />
              <Row k="round trip" v={`${data.database.roundTripMs} ms`} />
              <Row
                k="placement"
                v={
                  data.database.sameVm
                    ? `same VM — ${data.database.listenersOn5432} listener(s) on :5432`
                    : "remote"
                }
                accent={data.database.sameVm}
              />
            </Card>

            {/* ---------- network ---------- */}
            <Card icon={<Globe size={15} />} title="egress (from server route)" index="05">
              <Row
                k="internet"
                v={
                  data.network.egress.reachable
                    ? `reachable — HTTP ${data.network.egress.status} in ${data.network.egress.latencyMs}ms`
                    : "unreachable"
                }
                accent={!!data.network.egress.reachable}
                warn={!data.network.egress.reachable}
              />
              <Row k="target" v={data.network.egress.url} />
              <Row
                k="host hdr seen"
                v={data.previewSurface.headersSeenByServer["host"] ?? "—"}
              />
              <Row
                k="x-forwarded-host"
                v={
                  data.previewSurface.headersSeenByServer["x-forwarded-host"] ??
                  "—"
                }
              />
              <Row
                k="x-forwarded-proto"
                v={
                  data.previewSurface.headersSeenByServer[
                    "x-forwarded-proto"
                  ] ?? "—"
                }
              />
            </Card>

            {/* ---------- persistence ---------- */}
            <Card
              icon={<FileClock size={15} />}
              title="persistence probe"
              index="06"
              span
            >
              <Row k="marker file" v={data.persistence.markerFile} />
              <Row
                k="visible to server"
                v={data.persistence.found ? "yes — file survived into the running server process" : "no"}
                accent={data.persistence.found}
                warn={!data.persistence.found}
              />
              {data.persistence.contents && (
                <Row k="contents" v={data.persistence.contents} />
              )}
            </Card>

            {/* ---------- raw headers ---------- */}
            <Card
              icon={<Radio size={15} />}
              title="raw request headers (tokens redacted)"
              index="07"
              span
            >
              <pre className="max-h-56 overflow-auto whitespace-pre-wrap break-all rounded-lg bg-black/40 p-3 text-[11px] leading-relaxed text-[#8fb8a3]">
                {Object.entries(data.previewSurface.headersSeenByServer)
                  .sort(([a], [b]) => a.localeCompare(b))
                  .map(([k, v]) => `${k}: ${v}`)
                  .join("\n")}
              </pre>
            </Card>
          </div>
        )}

        <footer className="mt-10 flex items-center gap-2 border-t border-[rgba(52,245,162,0.14)] pt-5 text-[10px] tracking-[0.25em] text-[#41524a]">
          <TerminalSquare size={12} />
          <span>recon complete — arena / code arena sandbox</span>
          <Activity size={12} className="ml-auto text-[#34f5a2]" />
          <span className="flex items-center gap-1.5">
            <MemoryStick size={12} /> cgroups v2 · /user slice
          </span>
        </footer>
      </div>
    </main>
  );
}
