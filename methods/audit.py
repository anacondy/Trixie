#!/usr/bin/env python3
"""Audit trixie repo zips: md identity, manifest hash verification, key-number extraction."""
import hashlib, os, re, glob, json

ROOT = "/home/user"
TX = os.path.join(ROOT, "trixie_x")

def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()

PATTERNS = {
    "MemTotal":      re.compile(r"MemTotal:\s+\d+\s+kB"),
    "memmax_val":    re.compile(r"1947172864|\bmemory\.max[^\n]*"),
    "cpu_max":       re.compile(r"cpu\.max[^\n]*|100000\s*$", re.M),
    "ulimit_u":      re.compile(r"max user processes\s+-?\d+|-u\s+7917|7917"),
    "ulimit_n":      re.compile(r"open files\s+\d+"),
    "kernel":        re.compile(r"Linux version [^\s]+|#1 SMP[^\n]*|6\.1\.158"),
    "template_ids":  re.compile(r"nlhz8vlwyupq845jsdg9|a8bgno7gunor5wbj2d1w|TEMPLATE_ID[=:]\S+|BUILD_ID[=:]\S+|ENV_ID[=:]\S+"),
    "python_ver":    re.compile(r"Python 3\.\d+(\.\d+)?"),
    "node_ver":      re.compile(r"\bv20\.\d+\.\d+\b|20\.20\.2"),
    "nproc":         re.compile(r"nproc[^\d\n]{0,3}(\d+)|CPU\(s\):\s*(\d+)"),
    "gib_in_raw":    re.compile(r"\d\.\d+\s*GiB"),
}

MD_GIB = re.compile(r"[0-9.]+\s*GiB|1\.94|1\.894|1\.985|2\.032|2032608")

print("=== A) zip MD vs repo MD identity ===")
for i in range(1, 10):
    repo = glob.glob(f"{ROOT}/trixie/environment_characterization {i} *.md")
    repo = repo[0] if repo else None
    zips = glob.glob(f"{TX}/Agent {i} */**/environment_characterization.md", recursive=True)
    if not zips:
        zips = glob.glob(f"{TX}/Agent {i} */environment_characterization.md")
    if repo and zips:
        same = sha(repo) == sha(zips[0])
        print(f"Agent {i}: zip-md {'IDENTICAL' if same else 'DIFFERS'} to repo md ({len(zips)} md in zip)")
    else:
        print(f"Agent {i}: repo={bool(repo)} zip_md={len(zips)}")

print("\n=== B) manifest / SHA256SUMS internal verification ===")
sums_files = []
for dirpath, dirnames, filenames in os.walk(TX):
    for fn in filenames:
        if fn in ("SHA256SUMS", "SHA256SUMS.txt", "SHA256SUMS_ALL.txt") or fn.endswith(".sha256") or fn == "MANIFEST.sha256":
            sums_files.append(os.path.join(dirpath, fn))
line_re = re.compile(r"^([0-9a-fA-F]{64})[\s\*]+(\S.*)$")
for sf in sorted(sums_files):
    ok = miss = fail = 0
    base = os.path.dirname(sf)
    with open(sf, errors="replace") as f:
        for line in f:
            m = line_re.match(line.strip())
            if not m:
                continue
            want, rel = m.group(1).lower(), m.group(2).strip().lstrip("*")
            cand = [os.path.join(base, rel), os.path.join(base, os.path.basename(rel)),
                    os.path.join(os.path.dirname(base), rel)]
            hit = next((c for c in cand if os.path.isfile(c)), None)
            if hit is None:
                miss += 1
            elif sha(hit) == want:
                ok += 1
            else:
                fail += 1
                print(f"  HASH MISMATCH in {sf}: {rel}")
    print(f"{os.path.relpath(sf, TX)}: ok={ok} mismatch={fail} missing={miss}")

print("\n=== C) key numbers per agent (from raw files) ===")
for i in range(1, 10):
    adir = glob.glob(f"{TX}/Agent {i} *")
    if not adir:
        continue
    adir = adir[0]
    print(f"\n--- Agent {i} ({os.path.basename(adir).split()[-1]}) ---")
    agg = {k: {} for k in PATTERNS}
    nraw = 0
    for dirpath, dirnames, filenames in os.walk(adir):
        for fn in filenames:
            if fn.endswith((".txt", ".norm", ".log", ".tsv", ".json", ".csv")):
                p = os.path.join(dirpath, fn)
                nraw += 1
                try:
                    text = open(p, errors="replace").read()
                except OSError:
                    continue
                for k, rx in PATTERNS.items():
                    for m in rx.finditer(text):
                        s = m.group(0).strip()
                        if len(s) > 120:
                            s = s[:120]
                        agg[k][s] = agg[k].get(s, 0) + 1
    print(f"  raw-ish files scanned: {nraw}")
    for k in PATTERNS:
        if agg[k]:
            top = sorted(agg[k].items(), key=lambda kv: -kv[1])[:6]
            print(f"  {k}:")
            for s, c in top:
                print(f"     x{c}  {s}")

print("\n=== D) GiB / MemTotal claims in the 9 repo MDs ===")
for i in range(1, 10):
    repo = glob.glob(f"{ROOT}/trixie/environment_characterization {i} *.md")
    if not repo:
        continue
    print(f"\n--- report {i} ---")
    for n, line in enumerate(open(repo[0], errors="replace"), 1):
        if MD_GIB.search(line):
            print(f"  L{n}: {line.rstrip()[:150]}")
