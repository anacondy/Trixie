import os, resource, subprocess, json

res = {}
soft, hard = resource.getrlimit(resource.RLIMIT_NOFILE)
base = len(os.listdir("/proc/self/fd"))

# Phase 1: exhaust soft limit (1024) in THIS process; track exact fds to close
fds = []
try:
    while True:
        fds.append(os.dup(1))
except OSError as e:
    err = (e.errno, e.strerror)
print(f"phase1 soft=1024: opened {len(fds)} fds, then {err}")
res["phase1"] = {"extra_fds": len(fds), "baseline": base, "total_at_fail": base + len(fds), "errno": err[0], "msg": err[1]}
for fd in fds: os.close(fd)
assert len(os.listdir("/proc/self/fd")) == base, "fd cleanup failed"

def child(ulimit_val, outfile, label):
    with open(outfile, "w") as f:
        r = subprocess.run(["/bin/bash", "-c",
                            f"ulimit -n {ulimit_val} && python3 /home/user/ceiling/scripts/dup_loop.py"],
                           stdout=f, stderr=subprocess.STDOUT)
    txt = open(outfile).read().strip()
    print(f"{label} (soft->{ulimit_val}): {txt}  [rc={r.returncode}]")
    p = txt.split()
    res[label] = {"target_soft": ulimit_val,
                  "extra_fds_opened": int(p[1]) if p and p[0] == "COUNT" else None,
                  "errno": p[3] if p and p[0] == "COUNT" else None}
    return res[label]

child(65536, "/home/user/ceiling/out/fd_ph2.txt", "phase2")
child(524288, "/home/user/ceiling/out/fd_ph3.txt", "phase3")

with open("/home/user/ceiling/out/fd_ph4.txt", "w") as f:
    r = subprocess.run(["/bin/bash", "-c", "ulimit -n 700000; echo rc=$?"], stdout=f, stderr=subprocess.STDOUT)
txt = open("/home/user/ceiling/out/fd_ph4.txt").read().strip()
print(f"phase4 (try soft 700000 > hard 524288): {txt}")
res["phase4"] = {"shell_output": txt}
with open("/home/user/ceiling/out/fd_probe.json", "w") as f: json.dump(res, f, indent=1)
print("FD probe done")
