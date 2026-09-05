#!/usr/bin/env python3
"""make_manifest.py — build the per-run verification manifest for a probe.sh output dir.

Usage:
    python3 make_manifest.py [RAWDIR]        # default: ./raw

Writes RAWDIR/MANIFEST.txt (human readable), RAWDIR/manifest.json (machine readable)
and RAWDIR/SHA256SUMS.txt (so `sha256sum -c SHA256SUMS.txt` just works).

Fields per run: timestamp, sandbox id, template id, host identity, and SHA-256 of every
raw transcript — plus SHA-256 of the normalized form (timestamps/latencies masked) which is
the hash that should MATCH between two runs on the same environment.

Idempotent: safe to re-run any time (e.g. after copying the transcripts elsewhere, or to
exclude scratch files) — it only hashes, never mutates the transcripts.
"""
import datetime, hashlib, json, os, platform, re, subprocess, sys

OUTDIR = sys.argv[1] if len(sys.argv) > 1 else "./raw"
EXCLUDE_RE = re.compile(r"(^\.|(^|/)normalized(/|$)|MANIFEST\.txt$|manifest\.json$|^SHA256SUMS)")
VERSION = "1.1.0"


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def read_runid(outdir):
    p = os.path.join(outdir, ".run_id")
    if os.path.isfile(p):
        return open(p).read().strip()
    for f in sorted(os.listdir(outdir)):
        if f.endswith(".txt"):
            for line in open(os.path.join(outdir, f), errors="replace"):
                m = re.match(r"\s*run_id:\s*(\S+)", line)
                if m:
                    return m.group(1)
                if not line.startswith(" ="):
                    break
    return "unknown"


def parse_meta(outdir):
    """Pull the self-identifying header out of the first transcript."""
    meta = {}
    for f in sorted(os.listdir(outdir)):
        if not f.endswith(".txt"):
            continue
        for line in open(os.path.join(outdir, f), errors="replace"):
            m = re.match(r"\s*(run_id|started|sandbox|template|host|user|effective|probe\.sh v[\d.]+):\s*(.*)", line)
            if m:
                meta.setdefault(m.group(1), m.group(2).strip())
            if line.startswith("====") and meta:
                pass
        if len(meta) > 3:
            break
    return meta


def main():
    if not os.path.isdir(OUTDIR):
        sys.exit(f"no such dir: {OUTDIR}")
    run_id = read_runid(OUTDIR)
    meta = parse_meta(OUTDIR)

    entries = []
    for root, _dirs, files in os.walk(OUTDIR):
        for f in sorted(files):
            full = os.path.join(root, f)
            rel = os.path.relpath(full, OUTDIR)
            if EXCLUDE_RE.search(rel):
                continue
            e = {"file": rel, "bytes": os.path.getsize(full), "sha256": sha256(full)}
            stem = os.path.splitext(rel)[0]
            cand = [os.path.join(OUTDIR, "normalized", stem + ".norm"),
                    os.path.join(OUTDIR, "normalized", stem + ".txt.norm")]
            norm = next((c for c in cand if os.path.isfile(c)), None)
            e["sha256_normalized"] = sha256(norm) if norm else None
            e["normalized_file"] = os.path.relpath(norm, OUTDIR) if norm else None
            entries.append(e)
    entries.sort(key=lambda e: e["file"])

    env = {k: os.environ[k] for k in
           ("E2B_SANDBOX", "E2B_SANDBOX_ID", "E2B_TEMPLATE_ID", "E2B_EVENTS_ADDRESS") if k in os.environ}
    host = {
        "hostname": platform.node(),
        "os": (dict(l.rstrip().split("=", 1) for l in open("/etc/os-release") if "=" in l)
               .get("PRETTY_NAME", "").strip('"') if os.path.exists("/etc/os-release") else "?"),
        "kernel": platform.release(), "arch": platform.machine(),
        "python": platform.python_version(), "user": os.environ.get("USER", "?"),
        "cwd": os.getcwd(), "sandbox_id": env.get("E2B_SANDBOX_ID", "n/a"),
        "template_id": env.get("E2B_TEMPLATE_ID", "n/a"),
    }
    ts = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    doc = {
        "manifest_version": VERSION,
        "probe": "probe.sh",
        "run_id": run_id,
        "timestamp_utc": ts,
        "host": host,
        "environment": env,
        "transcript_header_seen": meta,
        "totals": {"files": len(entries), "bytes": sum(e["bytes"] for e in entries),
                   "matching_normalized": sum(1 for e in entries if e["sha256_normalized"])},
        "semantics": {
            "sha256": "hash of the verbatim transcript; will differ across hosts/runs by design",
            "sha256_normalized": ("hash after masking timestamps/durations/sizes/bandwidth/pids/tokens; "
                                  "equal values across two runs mean the environment matched on everything measurable"),
        },
        "files": entries,
    }
    with open(os.path.join(OUTDIR, "manifest.json"), "w") as f:
        json.dump(doc, f, indent=2)
        f.write("\n")

    # SHA256SUMS.txt in the exact format sha256sum -c expects
    with open(os.path.join(OUTDIR, "SHA256SUMS.txt"), "w") as f:
        for e in entries:
            f.write(f"{e['sha256']}  {e['file']}\n")
    with open(os.path.join(OUTDIR, "SHA256SUMS.normalized.txt"), "w") as f:
        for e in entries:
            if e["sha256_normalized"]:
                # path exactly as stored on disk, relative to OUTDIR, so `sha256sum -c` resolves it
                f.write(f"{e['sha256_normalized']}  {e['normalized_file']}\n")

    L = ["=" * 68,
         f" VERIFICATION MANIFEST — probe.sh transcripts (manifest v{VERSION})",
         "=" * 68,
         f"run_id          : {run_id}",
         f"timestamp_utc   : {ts}",
         f"sandbox_id      : {host['sandbox_id']}",
         f"template_id     : {host['template_id']}",
         f"host            : {host['hostname']} | {host['os']} | {host['kernel']} {host['arch']}",
         f"invoked by      : {host['user']} @ {host['cwd']}",
         f"python          : {host['python']}",
         f"environment vars: {', '.join(f'{k}={v}' for k, v in sorted(env.items())) or '(none)'}",
         f"contents        : {len(entries)} transcripts, {sum(e['bytes'] for e in entries):,} bytes",
         "",
         "-" * 68,
         "SHA-256 of verbatim transcripts   (expect these to differ on another host)",
         "-" * 68,
         f"  {'FILE':34} {'BYTES':>8}  SHA256",
         ]
    for e in entries:
        L.append(f"  {e['file']:34} {e['bytes']:>8}  {e['sha256']}")
    L += ["", "-" * 68,
          "SHA-256 of NORMALIZED transcripts (these should MATCH across equivalent runs)",
          "-" * 68,
          f"  {'FILE':34} {'HASH':>16}  status"]
    for e in entries:
        h = (e["sha256_normalized"] or "")[:16]
        L.append(f"  {e['file']:34} {h:>16}  {'normalized available' if h else 'no .norm file'}")
    L += ["", "-" * 68, "HOW TO VERIFY THIS RUN", "-" * 68,
          "  cd <this dir>",
          "  sha256sum -c SHA256SUMS.txt                 # verbatim integrity",
          "  sha256sum -c SHA256SUMS.normalized.txt      # masked integrity",
          "",
          "Reproduce and compare against your own run (from the directory ABOVE this one):",
          "  ./probe.sh /path/to/your_run --with-oom",
          "  python3 ./make_manifest.py /path/to/your_run",
          "  ./diff_run.sh <this dir> /path/to/your_run     # 0 differing transcripts => same environment",
          "",
          "Excluded from the manifest (not evidence): .bg_pid, .bg_ticks*, .run_id, .persist/, normalized/, MANIFEST.txt, manifest.json, SHA256SUMS*.txt",
          ""]
    open(os.path.join(OUTDIR, "MANIFEST.txt"), "w").write("\n".join(L))
    print(f"wrote MANIFEST.txt, manifest.json, SHA256SUMS.txt ({len(entries)} files, "
          f"{sum(e['bytes'] for e in entries):,} bytes)")
    print(f"  run_id={run_id} sandbox={host['sandbox_id']} template={host['template_id']}")


if __name__ == "__main__":
    main()
