export interface CmdResult {
  cmd: string;
  ok: boolean;
  stdout: string;
  stderr: string;
}

export interface MarkerFileReport {
  path: string;
  ok: boolean;
  count: number;
  lines: string[];
  error?: string;
}

export interface EgressProbe {
  url: string;
  ok: boolean;
  status: number | null;
  ms: number;
  error?: string;
}

export interface EnvReport {
  generatedAt: string;
  vmUptimeSec: number | null;
  process: {
    nodeVersion: string;
    pid: number;
    cwd: string;
    uptimeSec: number;
    startedAt: string;
    id: string;
  };
  template: {
    packageName: string;
    observedUiLabel: string;
    e2bFile: CmdResult;
    e2bEnv: CmdResult;
    templateId: string | null;
    buildId: string | null;
    sandboxId: string | null;
    eventsAddress: string | null;
    referenceId: string;
    verdict: "same" | "different" | "unknown";
  };
  machine: {
    uname: CmdResult;
    hostname: CmdResult;
    virt: CmdResult;
    nproc: CmdResult;
    memTotal: CmdResult;
  };
  cgroups: {
    fsType: string;
    rootMemoryMax: string;
    rootMemoryCurrent: string;
    rootCpuMax: string;
    userMemoryMax: string;
    userMemoryCurrent: string;
    userCpuMax: string;
    memoryMaxBytes: number | null;
    memoryCurrentBytes: number | null;
  };
  database: {
    urlSet: boolean;
    scheme: string | null;
    host: string | null;
    port: string | null;
    version: CmdResult;
    currentDbUser: CmdResult;
    listener: CmdResult;
    isLocal: boolean;
    localNote: string;
  };
  network: {
    probes: EgressProbe[];
    egressIp: string | null;
    dns: CmdResult;
  };
  preview: {
    host: string;
    proto: string;
    classification: "e2b" | "arena" | "vercel" | "localhost" | "other";
    requestHeaders: Record<string, string>;
    selfFetch: {
      ok: boolean;
      url: string;
      status: number | null;
      note: string;
      headers: Record<string, string>;
    };
  };
  persistence: {
    nowMarker: string;
    files: MarkerFileReport[];
    db: {
      ok: boolean;
      rowCount: number | null;
      latest: { id: number; marker: string; source: string; createdAt: string }[];
      error?: string;
    };
  };
}
