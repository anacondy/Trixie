import sys, os, subprocess, time, json, signal

BASE = "/sys/fs/cgroup/user"
def rd(p):
    try:
        with open(p) as f: return f.read().strip()
    except Exception as e: return f"ERR {e}"
def events():
    d = {}
    for line in rd(BASE+"/memory.events").splitlines():
        k, v = line.split()
        d[k] = int(v)
    return d
def current_MB():
    return int(rd(BASE+"/memory.current")) / 1048576.0
def avail_MB():
    with open("/proc/meminfo") as f:
        for line in f:
            if line.startswith("MemAvailable"):
                return int(line.split()[1]) / 1024.0

CHILD = ("import sys,time; n=int(sys.argv[1]); t=time.time();"
         "print('pid',os.getpid(),flush=True);"
         "b=bytearray(n*1024*1024); b[::4096]=bytes(len(b[::4096]));"
         "print('ok', n, 'elapsed', round(time.time()-t,2), flush=True)")
CHILD = CHILD.replace("import sys,time;", "import sys,time,os;")

rows = []
def probe(mib, phase, idx):
    e0 = events(); c0 = current_MB(); a0 = avail_MB()
    t0 = time.time()
    try:
        r = subprocess.run([sys.executable, "-c", CHILD, str(mib)],
                           capture_output=True, text=True, timeout=600)
        rc = r.returncode
        out = r.stdout.strip().splitlines()
        err = r.stderr.strip().splitlines()
        ok = (rc == 0 and out and out[-1].startswith("ok"))
        kind = "ok" if ok else ("SIGKILL" if rc == -9 else ("rc%d" % rc))
        note = ""
        if not ok:
            for l in (err[-2:] if err else []):
                if "MemoryError" in l or "Cannot allocate" in l or "mmap" in l:
                    kind = "ENOMEM"; break
            if ok is False and rc not in (-9,):
                note = (err[-1] if err else out[-1] if out else "")[:90]
        rows.append(dict(phase=phase, idx=idx, mib=mib, rc=rc, kind=kind,
                         sec=round(time.time()-t0, 2), cur0=round(c0,1),
                         avail0=round(a0,1), oom0=e0["oom_kill"],
                         oom1=events()["oom_kill"], note=note))
        print(f"{phase:>4} {idx:>3} {mib:>6} MiB -> rc={rc:>4} {kind:8} "
              f"{round(time.time()-t0,2):>6}s cur={round(c0,1):>7.1f} avail={round(a0,1):>7.1f} "
              f"oomKill {e0['oom_kill']}->{events()['oom_kill']} {note}", flush=True)
        return ok
    except subprocess.TimeoutExpired:
        rows.append(dict(phase=phase, idx=idx, mib=mib, rc="TO", kind="timeout",
                         sec=round(time.time()-t0,2), cur0=round(c0,1),
                         avail0=round(a0,1), oom0=e0["oom_kill"],
                         oom1=events()["oom_kill"], note=""))
        print(f"{phase:>4} {idx:>3} {mib:>6} MiB -> TIMEOUT", flush=True)
        return False

def dump(tag):
    with open(f"/home/user/ceiling/out/{tag}.json", "w") as f:
        json.dump(rows, f, indent=1)
    with open(f"/home/user/ceiling/out/{tag}.tsv", "w") as f:
        f.write("phase\tidx\tmib\treturncode\toutcome\telapsed_s\tcur_pre_MiB\tavail_pre_MiB\toomKill_pre\toomKill_post\tnote\n")
        for r in rows:
            f.write("\t".join(str(r[k]) for k in
                    ["phase","idx","mib","rc","kind","sec","cur0","avail0","oom0","oom1","note"])+"\n")

def main():
    print("preamble: memory.max =", rd(BASE+"/memory.max"), "current =", current_MB(), "MiB",
          "overcommit =", rd("/proc/sys/vm/overcommit_memory"), flush=True)
    idx = 0
    # Phase 1: 128 MiB steps upward from 128 MiB
    last_ok, first_fail = None, None
    m = 128
    while m <= 2048:
        idx += 1
        ok = probe(m, "STEP", idx)
        if ok:
            last_ok = m
        else:
            first_fail = m
            break
        m += 128
    # Phase 2: bisect (last_ok, first_fail) to <=32 MiB
    if last_ok is not None and first_fail is not None:
        lo, hi = last_ok, first_fail
        while hi - lo > 32:
            mid = (lo + hi) // 2
            idx += 1
            if probe(mid, "BISECT", idx):
                lo = mid
            else:
                hi = mid
        last_ok, first_fail = lo, hi
    # Phase 3: confirm boundary
    idx += 1
    probe(last_ok, "CONFIRM", idx)
    if first_fail is not None:
        idx += 1
        probe(first_fail, "CONFIRM", idx)
    print(f"\nRESULT last_success={last_ok} MiB first_kill={first_fail} MiB (gap {None if first_fail is None else first_fail-last_ok} MiB)")
    print("final events:", events())
    dump("memory_probes")

if __name__ == "__main__":
    main()
