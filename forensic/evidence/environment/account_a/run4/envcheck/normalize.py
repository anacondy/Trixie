#!/usr/bin/env python3
"""normalize.py — mask run-to-run volatile values in probe.sh transcripts.

Usage:
    python3 normalize.py FILE...            # writes <dir>/normalized/<name>.norm
    python3 normalize.py --stdout FILE      # print normalized text

Purpose: lets a third party diff their probe.sh run against the published baseline
without drowning in noise. Everything that legitimately changes between two runs of the
same environment (timestamps, latency, throughput, memory currently in use, PIDs, load
average, token/id strings, column-alignment whitespace) is masked to a typed placeholder.
What SURVIVES masking is the part worth auditing: available tooling, versions, limits,
mount layout, capability bits, enabled flags, error strings.

Keep the rule list ordered: specific patterns before generic ones, whitespace collapse last.
"""
import re, sys, os

PATS = [
    # 1. whole-line drops happen before substitution (see DROP_PREFIXES)
    # semver-like strings (probe.sh version, package versions stay - they are evidence)
    (r"(?<![0-9a-zA-Z.])\d+\.\d+\.\d+(?![0-9])", "<VER>"),
    # inline run ids / ids embedded in text
    (r"(?i)run_id[=: ]\S+", "run_id=<ID>"),
    (r"(?i)RUN_ID=\S+", "RUN_ID=<ID>"),
    # timestamps
    (r"\b\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(Z)?\b", "<TS>"),
    (r"\b\d{2}:\d{2}:\d{2}\b", "<TIME>"),
    (r"\b\w{3} \d{1,2} \d{2}:\d{2}:\d{2} \d{4}\b", "<CTS>"),        # ctime / `date` style
    (r"\b[A-Z][a-z]{2} [ A-Z]\d{1,2} \d{2}:\d{2}:\d{2} \d{4}\b", "<CTS>"),
    # durations / rates / sizes
    (r"\b\d+(\.\d+)? ?(ns|us|ms|s|sec|seconds|minutes)\b", "<T>"),
    (r"\b\d+(\.\d+)? ?(MiB|GiB|KiB|MB|GB|KB|kB|B/s|bytes)\b", "<SZ>"),
    (r"\b\d+(\.\d+)?(Gi|Mi|Ki)\b", "<SZ>"),                            # free -h columns
    (r"\b\d+(\.\d+)? ?(Mbps|Gbps|kpps)\b", "<BW>"),
    (r"\b\d+(\.\d+)??[TGM]B?\b", "<SZ>"),
    # volatile kernel counters and tables
    (r"^\s*[\d.]+ [\d.]+ [\d.]+ \d+/\d+\s+\d+\s*$", "<LOADAVG>"),      # /proc/loadavg
    (r"load average:.*", "load average: <LOADAVG>"),
    (r"^\s*(Mem|Swap|Buffers|Cache|Total|Used|Free|Avail)\s*:.*$", r"\1: <MEM>"),
    (r"\bMem(Total|Available|Free|Used):.*", "Mem\\1: <N> kB"),
    (r"usage_usec \d+", "usage_usec <N>"),
    (r"oom_kill \d+", "oom_kill <N>"),
    (r"(rbytes|wbytes|rios|wios)=\d+", "\\1=<N>"),
    (r"current \d+|max \d+", "current <N>|max <N>"),
    # process-table noise: TIME (MM:SS or HH:MM:SS) and the VSZ/RSS columns
    (r"\b[A-Z][a-z]{2} {1,2}\d{1,2} \d{2}:\d{2}\b", "<LS_TIME>"),          # `ls -l` mtime
    (r"\b[A-Z][a-z]{2} {1,2}\d{1,2}  ?\d{4}\b", "<LS_YEAR>"),                # `ls -l` with year
    (r"\b\d{1,3}:\d{2}:\d{2}\b", "<CLOCK>"),
    (r"\b\d{1,3}:\d{2}\b", "<CLOCK>"),
    (r"^(\s*\d+\s+\d+\s+\S+\s+\S+\s+<CLOCK>\s+)\d+\s", r"\1<N> "),
    (r"^(\s*\S+\s+\d+\s+\S+\s+\d+\s+\d+\s+<CLOCK>\s+)(\d[\d.]*k?\s+){4}", r"\1<PS> "),
    # systemd/journal relative times and socket queue counters
    (r"\(\d+ (?:min|s|h|days?) ago\)", "(<AGO>)"),
    (r"^─?\s*[a-z_.@/\\-]+:\d+\s+\d+\s+\d+\s", "<SOCK>"),
    # scratch-path noise: mktemp dirs, PID-suffixed probe scratch files, run stamps
    (r"/tmp/tmp\.[A-Za-z0-9]+", "<TMPDIR>"),
    (r"\.probe_rw_\d+", ".probe_rw_<PID>"),
    (r"probe_persist_\S+", "probe_persist_<ID>"),
    (r"T\d{6}Z-\d+", "T<STAMP>-<PID>"),
    # kernel worker threads carry whatever work they last did - not environment state
    (r"\bkworker\S*", "<KWORKER>"),
    (r"\bkworker/<KWORKER>", "<KWORKER>"),
    # kernel audit lines are per-session; drop them (they carry no environment state)
    (r"^\[[\s\d.]+\] audit:.*$", "<AUDIT_LINE>"),
    # `systemctl` next-fire dates and unit substate vary between runs
    (r"\b[A-Z][a-z]{2} \d{4}-\d{2}-\d{2}\b", "<DATE>"),
    (r"^Active: active \(\w+\)", "Active: active (<SUBSTATE>)"),
    # df: usage counts change because the probe itself writes files
    (r"^(tmpfs|/dev/\S+|overlay|\S+fs)\s+[\d.]+[a-z]?\s+[\d.]+[a-z]?\s+[\d.]+[a-z]?\s+\d+%\s+(\S+)$", r"\1 <DF> \2"),
    # identifiers that differ every run
    (r"pid=\d+", "pid=<PID>"),
    (r"\bpid \d+\b", "pid <PID>"),
    (r"pidfile\S*", "<PIDFILE>"),
    (r"(0x)?[0-9a-f]{8,}", "<HEX>"),
    (r"\b\d{5,}\b", "<BIGNUM>"),
    (r"\b\d+\.\d+\b", "<NUM>"),
    (r"\b[A-Za-z0-9]{16,}\b", "<TOKEN>"),
]
# Header lines that exist only to identify the run: drop them entirely so a run from
# another host still diffs clean on content.
DROP_PREFIXES = (" started:", " run_id:", " sandbox:", " template:", "RUN_ID=",
                 "  total wall time:", "  probe finished:", "manifest written by", "$ END")


# ps variants: "pid ppid user TIME VSZ args" or "pid ppid user stat TIME VSZ args"
PS_SHAPE = re.compile(r"^\s*\d+\s+\d+\s+\S+\s+(?:\S+\s+)?\d{1,3}:\d{2}(?::\d{2})?\s")


def norm_lines(lines):
    out = []
    for line in lines:
        # stat tables (memory.stat, /proc/net/dev, cpu.stat): every value is a live counter
        if re.match(r"^\s*[\w/.-]+:?\s+(?:\d+\s+)+$", line):
            line = re.sub(r"\b\d+\b", "<N>", line)
        if PS_SHAPE.match(line):
            # pid ppid user stat TIME VSZ [RSS] CMD -> mask VSZ/RSS columns, keep everything else
            line = re.sub(r"(\s)\d{2,7}(?=\s+\S)", r"\1<N>", line)
        if line.startswith(DROP_PREFIXES) or "run_id=" in line.lower() and len(line) < 40:
            continue
        for pat, rep in PATS:
            line = re.sub(pat, rep, line)
        line = re.sub(r" {2,}", " ", line).rstrip()   # last: kill column-alignment noise
        out.append(line)
    return "\n".join(out) + "\n"


def norm(path):
    with open(path, errors="replace") as f:
        return norm_lines(f)


if __name__ == "__main__":
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    if args[0] == "--stdout":
        sys.stdout.write(norm(args[1]))
        raise SystemExit(0)
    for fp in args:
        base, _ext = os.path.splitext(os.path.basename(fp))
        d = os.path.join(os.path.dirname(os.path.abspath(fp)), "normalized")
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, base + ".norm"), "w") as w:
            w.write(norm(fp))
