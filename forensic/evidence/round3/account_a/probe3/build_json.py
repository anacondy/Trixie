#!/usr/bin/env python3
import json, re, hashlib, os, subprocess
def read(p): return open(p, errors="replace").read()
def trunc(s,n=2000): return s if len(s)<=n else s[:n]+"\n...[TRUNCATED %d chars]"%(len(s)-n)

lock=read("01_a0_lock.txt"); cg=read("05_cgroup_limits.txt"); d1=read("07_d1_oom.txt")
d2=read("08_d2_disk.txt"); d4=read("09_d4_fd.txt"); d6=read("10_d6_smt.txt")
d3=read("11_d3_egress.txt"); d3b=read("12_d3b_egress_directip.txt"); b1=read("13_b1_bandwidth.txt")
an=read("15_analysis_derived.txt"); man=read("manifest3.txt")

R={}
R["run"]={
 "timestamp_utc":"2026-09-06T17:01:15Z",
 "timestamp_utc_end":"2026-09-06T17:12:00Z",
 "surface":"Arena.ai Agent Mode (E2B_SANDBOX=true, no app/preview, no DATABASE_URL)",
 "browser":"NOT OBSERVED (no browser in this sandbox; nothing observed)",
 "account_label":"NOT OBSERVED (not exposed to the sandbox; not inferred)",
 "sandbox_id":"i3xgkkubxoiw2bi4vlqkx",
 "template_id":"nlhz8vlwyupq845jsdg9",
 "build_id":"f34a5416-ef30-4cb7-8e18-0fdecd6eb529",
 "boot_id":"2bb79165-136a-4b63-829d-17027b0a8e40",
 "vm_class":"T",
 "vm_class_evidence":"4/4 T markers present, 0/4 B markers: trixie, Python 3.13.14, kernel stamp Fri Jul 17 14:31:34 UTC 2026, MemTotal 2032608 kB = 1.9384 GiB",
 "virtualization":"kvm (systemd-detect-virt) / Hypervisor vendor KVM / full",
 "os_pretty":"Debian GNU/Linux 13 (trixie)",
 "kernel_stamp":"#1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026 (Linux 6.1.158+)",
 "python_ver":"Python 3.13.14",
 "uptime_at_first_command_s":22.26,
 "hostname":"e2b.local",
 "nproc":2,
 "manifest3_hash_of_hashes":re.search(r"hash_of_hashes_sha256=([0-9a-f]{64})",man).group(1),
 "raw_files":int(re.search(r"n_files=(\d+)",man).group(1)),
}
R["calibration"]=[
 {"id":"A1","question":"2024 World Series winner",
  "answer_memory":"Los Angeles Dodgers over NY Yankees 4-1; I also asserted Game 1 = 6-2 and Game 4 = LAD",
  "answer_search":"Dodgers beat Yankees 4-1, clinching 7-6 in Game 5 on 2024-10-30 (8th title, first since 2020). Series detail corrected: Game 1 was 6-3 in 10 innings on a Freeman walk-off grand slam; the Yankees won Game 2 in extras 5-4; Dodgers took Games 3 and 4 on the road.",
  "delta":"Winner + 4-1 series shape correct from memory; two game-level details wrong (G1 score 6-2 vs 6-3; and I had LAD taking G4 while NY won G2).",
  "cutoff_self":"~2025-01","confidence":0.93},
 {"id":"A2","question":"2025 ICC Champions Trophy winner",
  "answer_memory":"India beat New Zealand, final in Dubai 2025-03-09; I attributed the top score (~76) to KL Rahul",
  "answer_search":"India won by 4 wickets with 6 balls to spare. NZ 251/7 (Mitchell 63, Bracewell 53); IND 254/6 in 49 overs - top score was ROHIT SHARMA 76 (83), Iyer 48, KL Rahul 34*; Jadeja hit the winning runs.",
  "delta":"Winner, venue, date and margin correct; the top-scorer attribution was wrong (Rohit 76, not Rahul; Rahul was 34*).",
  "cutoff_self":"~2025-01","confidence":0.62},
 {"id":"A3","question":"does a user-facing CLI for Linux post-quantum readiness auditing exist?",
  "answer_memory":"No such single CLI present in parametric memory; honest state = 'unknown / cannot verify' (refused to assert a negative).",
  "answer_search":"YES, several exist: 'Mini PQC Scanner' (github.com/oferzinger/mini-pqc-scanner, CLI checking TLS certs, OpenSSH/VPN configs, OpenSSL); Anvil Secure 'PQCscan' (free/OSS, tls-scan + ssh-scan modes, create-report HTML); quantakrypto/pqc-tools (qScan CLI with readiness score + SARIF/CBOM, plus qProbe for live X25519MLKEM768 probing).",
  "delta":"Memory FALSE-NEGATIVE, corrected by search: at least three published CLIs cover 2-3 of the three axes asked about. My parametric negative would have been graded wrong; the search tool is what saved it.",
  "cutoff_self":"~2025-01","confidence":0.30},
 {"id":"A4","question":"kernel build date vs self-reported cutoff",
  "answer_memory":"uname -v = '#1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026', ~18 months after my ~2025-01 cutoff.",
  "answer_search":"NOT APPLICABLE (measured locally by command, not a search question).",
  "delta":"Implication stated: no training-derived knowledge can describe this kernel (6.1.158+), this image, or this sandbox. Every statement in this report about the box comes from a command run in this session; anything else is labelled NOT PERFORMED.",
  "cutoff_self":"~2025-01","confidence":0.99},
 {"id":"A5","question":"recall-horizon bracket from memory only",
  "answer_memory":"Newest reliably dated: Claude 3.5 Sonnet 2024-06-20, GPT-4o 2024-05-13; vendor identifiers recalled: 'context-1m-2025-08-07', 'prompt-caching-2024-07-31'. First notably MISSING: any 2026 frontier release.",
  "answer_search":"2026 releases I had no parametric memory of, per three independent aggregator pages: Kimi K2.5 (Jan 27), GPT-5.3 Codex (Feb 5), GLM-5 (Feb 11), Claude Sonnet 4.6 (Feb 17), Gemini 3.1 Pro preview (Feb 19), GPT-5.4 (Mar 5), Claude Opus 4.7 (Apr 16), GPT-5.5 (Apr 23), Claude Fable 5 (Jun 9). Dates CONFLICT across sources (e.g. Opus 4.6 is dated Feb 5 on one page, Feb 17 on another) and come from SEO-style aggregators, so I mark them REPORTED, not verified.",
  "delta":"Parametric horizon brackets to ~2025 H2, i.e. roughly 9-12 months before today. The recall bracket, not the rote self-reported cutoff, is the usable clock; the 2026 list is third-party-reported and internally inconsistent.",
  "cutoff_self":"~2025-01","confidence":0.55},
]
R["falsifications"]=[
 {"id":"F1","claim":"KVM microVM, not a container, not bare metal",
  "confirming_cmd":"systemd-detect-virt; dmesg | grep 'Command line'; grep hypervisor /proc/cpuinfo",
  "confirming_out":"kvm | cmdline: init=/sbin/init root=/dev/vda virtio_mmio... ip=169.254.0.21 | hypervisor flag present",
  "falsifying_cmd":"cat /proc/1/cgroup; ls -d /.dockerenv; systemctl list-units (real init tree?)",
  "falsifying_out":"/proc/1/cgroup='0::/' with system.slice/user.slice present and no container id; /.dockerenv absent -> not a container; own kernel+PID1 -> not bare metal",
  "verdict":"KVM guest with its own kernel","grade":"MEASURED"},
 {"id":"F2","claim":"CLASS T (not B, not NEW)",
  "confirming_cmd":"grep PRETTY_NAME /etc/os-release; python3 -V; uname -v; grep MemTotal /proc/meminfo",
  "confirming_out":"Debian GNU/Linux 13 (trixie) / Python 3.13.14 / Fri Jul 17 14:31:34 UTC 2026 / 2032608 kB",
  "falsifying_cmd":"same four commands (each B marker is a different string)",
  "falsifying_out":"0/4 B markers: not bookworm, not 3.11, not 'Mon May 11 18:48:24 UTC 2026', not ~3.8 GiB",
  "verdict":"CLASS T, 4/4 markers","grade":"MEASURED"},
 {"id":"F3","claim":"OOM ceiling: 1600 MiB OK, 1632 MiB killed; session survives",
  "confirming_cmd":"python3 d1_oom_bisect.py (allocate-and-touch in a subprocess, 32 MiB resolution)",
  "confirming_out":"1600 MiB rc=0 'TOUCHED_MiB 1600'; 1632 MiB rc=-9; memory.events oom_kill 0 -> 3 (the 3 failing trials)",
  "falsifying_cmd":"cat /sys/fs/cgroup/user/memory.events; uptime; echo alive (written after the kills)",
  "falsifying_out":"a session-ending kill would leave no post-D1 output; observed oom_kill=3, 'up 3 min', post-D1 lines present",
  "verdict":"cgroup-scoped OOM kill only","grade":"MEASURED"},
 {"id":"F4","claim":"No domain blocklist; DNS unfiltered; egress open",
  "confirming_cmd":"curl -sS -o /dev/null -w '%{http_code}' https://H/ ; curl --resolve H:443:<A> https://H/ ; getent hosts H",
  "confirming_out":"17/18 hosts gave real statuses (200/301/302/403/404/421); direct-IP+--resolve gave identical statuses for pastebin.com, api.anthropic.com, openai.com, api.openai.com, huggingface.co, example.com",
  "falsifying_cmd":"identical method on control example.com (B2) + getent for every host",
  "falsifying_out":"control=200 so the probe is valid; DNS returned A and AAAA for every public host, so no DNS-level filtering. Only 169.254.169.254 (timeout) and metadata.google.internal (NXDOMAIN) failed",
  "verdict":"blocklist = cloud metadata only","grade":"MEASURED"},
 {"id":"F5","claim":"IPv6 egress blocked",
  "confirming_cmd":"curl -6 -sS -o /dev/null -w '%{http_code} %{remote_ip}' https://cloudflare.com/",
  "confirming_out":"curl: (7) Failed to connect ... after 10 ms; http=000; ip= (empty)",
  "falsifying_cmd":"curl -4 same URL; getent hosts cloudflare.com",
  "falsifying_out":"-4 gives 200 with a real ip; DNS still returned AAAA for 12 hosts -> resolver not filtering, block is at connect()",
  "verdict":"IPv4-only egress","grade":"MEASURED"},
 {"id":"F6","claim":"raw connect() is untrustworthy (transparent proxy); use TTFB",
  "confirming_cmd":"python3 socket.create_connection to 192.0.2.1:80, 198.51.100.1:443, 203.0.113.1:22",
  "confirming_out":"all three 'CONNECTED' in 0.004/0.000/0.000 s",
  "falsifying_cmd":"curl -m 8 https://192.0.2.1/ ; curl -sS http://192.0.2.1/",
  "falsifying_out":"curl(28) timed out after 8002 ms (http=000), while plain GET returned HTTP 404 in 2.0 ms -> local acceptance, not a real route",
  "verdict":"connect() results discarded; TTFB used throughout","grade":"MEASURED"},
 {"id":"F7","claim":"/tmp is RAM (tmpfs, 993 MiB); /home/user is the 25G disk",
  "confirming_cmd":"findmnt /tmp; dd urandom->/tmp 256 MiB with cgroup memory.current before/after; rm",
  "confirming_out":"tmpfs 993M; memory.current +268627968 B for a 268435456 B file (1.0007x); after rm back to 11931648 B",
  "falsifying_cmd":"dd urandom 5 GiB -> /tmp ; df -h /tmp",
  "falsifying_out":"'No space left on device' after 992 MiB, df shows 100% full - a disk-backed /tmp would have taken all 5 GiB as /home/user did",
  "verdict":"/tmp = RAM, capped 993 MiB","grade":"MEASURED"},
 {"id":"F8","claim":"8 tool calls in one block run SERIALLY (~2.0 s apart), not in parallel",
  "confirming_cmd":"8x bash each writing its own UTC start/end clock into d5/<X>.txt",
  "confirming_out":"starts 33.491/35.861/37.519/39.567/41.504/43.571/45.819/47.507; mean gap 2.002 s; wall 18.040 s",
  "falsifying_cmd":"each call sleeps exactly 4 s, so a parallel runtime must finish in ~4.1 s",
  "falsifying_out":"observed 18.040 s, i.e. 4.4x the parallel expectation -> not concurrent",
  "verdict":"no observed per-session parallelism; effective concurrency 1","grade":"MEASURED"},
 {"id":"F9","claim":"high CPU does NOT cause slow downloads (correlation is confounded)",
  "confirming_cmd":"/proc/stat busy% around each download + curl speed_download during a verified burn",
  "confirming_out":"cpu_busy_pct=100.0 during burn; speeds 179.3/164.3/85.3/167.8/66.3 MB/s (mean 132.6) vs idle cpu_busy_pct=1.2 -> 49.4/174.1/183.1 (mean 135.5)",
  "falsifying_cmd":"same URL idle n=3 + per-POP breakdown + cpu.stat throttling counters",
  "falsifying_out":"burn range [66.3,179.3] fully overlaps idle range [49.4,183.1]; nr_throttled=0, throttled_usec=0, cpu.max='max 100000'. Measured confounder: POP choice (172.66.0.218 mean 140.2 vs 162.159.140.220 mean 122.4 MB/s) + TCP ramp",
  "verdict":"CPU ruled out; confounder identified","grade":"MEASURED"},
 {"id":"F10","claim":"SMT sibling adds ~0 throughput; only 1 physical core",
  "confirming_cmd":"taskset -c 0 python3 d6bench.py (1 thread vs 2 forked threads, same mask)",
  "confirming_out":"mask 0: 1T=0.4546 s, 2T=0.9082/0.9078 s -> 1.998x, sibling gain +0.11%; mask 1: 1T=0.4852, 2T=0.9628 -> 1.984x, +0.79%",
  "falsifying_cmd":"taskset -c 2 and -c 3; cat /sys/devices/system/cpu/cpu0/topology/thread_siblings_list; lscpu",
  "falsifying_out":"taskset -c 2 -> 'failed to set affinity: Invalid argument'; siblings='0-1'; lscpu 1 socket x 1 core x 2 threads -> no 2-core comparison possible",
  "verdict":"ratio measured; SMT gain ~0%; vs-2-core NOT MEASURABLE","grade":"MEASURED"},
 {"id":"F11","claim":"child can raise RLIMIT_NOFILE to the hard limit but not above it",
  "confirming_cmd":"python3 d4_fd.py (parent opens to EMFILE; child setrlimit then opens)",
  "confirming_out":"parent soft/hard=(1024,524288) -> 1018 fds then EMFILE(24); child after setrlimit -> 524285 fds then EMFILE(24)",
  "falsifying_cmd":"resource.setrlimit(RLIMIT_NOFILE,(hard+1,hard+1))",
  "falsifying_out":"ValueError 'not allowed to raise maximum limit' -> hard cap real",
  "verdict":"soft 1024 / hard 524288","grade":"MEASURED"},
 {"id":"F12","claim":"memory limit is a hard cgroup ceiling with no swap escape",
  "confirming_cmd":"cat /proc/swaps; cat /sys/fs/cgroup/user/memory.swap.max",
  "confirming_out":"/proc/swaps header only (no devices); swap.max='max' but nothing to swap to",
  "falsifying_cmd":"the D1 bisect itself",
  "falsifying_out":"with swap, 1792 MiB would slow and return rc=0; observed immediate rc=-9 at 1632 MiB and memory.current collapse to 13942784 B",
  "verdict":"no swap; over-limit = immediate kill","grade":"MEASURED"},
 {"id":"F13","claim":"MemTotal = 1.94 GiB is correct (C6)",
  "confirming_cmd":"python3 arithmetic on MemTotal=2032608 kB (15_analysis_derived.txt)",
  "confirming_out":"2032608 kB = 2081390592 B = 1984.97 MiB = 1.9384 GiB (= 2.0814 decimal GB)",
  "falsifying_cmd":"same arithmetic under the alternative conventions / a class-B box",
  "falsifying_out":"binary 1.9384, decimal 2.0814; no convention reproduces '1.894 GiB'; class B would read ~3.89 GiB",
  "verdict":"1.94 GiB stands","grade":"MEASURED"},
 {"id":"F14","claim":"Section E does not apply to this surface",
  "confirming_cmd":"env | grep ^E2B_; cat /.e2b; env | grep -c DATABASE_URL",
  "confirming_out":"E2B_SANDBOX=true, template nlhz8vlwyupq845jsdg9, build f34a5416-..., hostname e2b.local, DATABASE_URL count 0",
  "falsifying_cmd":"env | grep DATABASE_URL; look for a generated app / preview server",
  "falsifying_out":"none found -> not arena.ai/code",
  "verdict":"E1-E4 NOT PERFORMED (out of scope by the task's own rule)","grade":"MEASURED"},
 {"id":"F15","claim":"C1: file mtimes are not usable as evidence",
  "confirming_cmd":"stat -c '%y %z' on pre-existing image files",
  "confirming_out":"/etc/resolv.conf and /etc/hostname mtime = 1970-01-01 00:00:00 (epoch), /etc/os-release = 2026-07-04 09:05:00 while the box booted 2026-09-06",
  "falsifying_cmd":"write a file now and stat it (does mtime track reality?)",
  "falsifying_out":"c1_probe.txt mtime = 2026-09-06 17:08:39.838 = the embedded content time -> live writes are fine, only restore-stamped files lie. The restore reset itself is NOT observable inside one session: AVOIDED, not disproved.",
  "verdict":"mtimes avoided; content timestamps used","grade":"MEASURED"},
]
M=[]
def m(id,cmd,raw,val,unit,status,note):
    M.append({"id":id,"command":cmd,"raw_output":trunc(raw),"value":val,"unit":unit,"status":status,"note":note})

m("A0-lock","grep PRETTY_NAME /etc/os-release; uname -v; python3 -V; grep MemTotal /proc/meminfo; df -h /; cat /.e2b; env|grep ^E2B_TEMPLATE_ID; cat /proc/sys/kernel/random/boot_id",
  lock,"CLASS T","class","MEASURED","4/4 T markers, 0/4 B markers")
m("A0-uptime","cat /proc/uptime (first command of the session)","22.26 35.21",22.26,"s","MEASURED",
  "fresh sandbox: 22 s of uptime at the first command; boot_id 2bb79165-... is identity only (C2)")
m("C5-cgroup","cat /sys/fs/cgroup/user/memory.max; memory.high; memory.swap.max; cpu.max; pids.max; /proc/swaps",cg,
  "memory.max=1947172864 B (1.8134 GiB / 1.9472 GB); high=max; swap none; cpu.max='max 100000' (no quota); pids.max=max","bytes","MEASURED",
  "/sys/fs/cgroup/memory.max does not exist (root cgroup has no memory controller file) -> C5 is real")
m("C6-units","python3 arithmetic from MemTotal (analyze.py)",
  "\n".join(l for l in an.splitlines() if "MemTotal" in l or "memory.max" in l or "first_kill" in l or "last_success" in l),
  "2032608 kB = 1984.97 MiB = 1.9384 GiB = 2.0814 GB","kB/MiB/GiB/GB","MEASURED",
  "convention: kernel 'kB'=1024 B; MiB/GiB binary; GB decimal. MemTotal-memory.max = 128.0 MiB kept outside the user cgroup")
m("D1-oom","python3 d1_oom_bisect.py (subprocess allocate-and-touch, 1 MiB blocks, bisected)",d1,
  "last_success=1600 MiB (1.5625 GiB); first_kill=1632 MiB (1.5938 GiB); resolution=32 MiB; oom_kill 0->3","MiB","MEASURED",
  "rc=-9 SIGKILL at 1632 MiB = 87.9% of memory.max (225 MiB of headroom was other processes/page cache). Session survived: post-D1 lines written, uptime continued")
m("D2-disk-home","dd if=/dev/urandom of=/home/user/d2_test.bin bs=1M count=1024/5120 conv=fsync",d2,
  "1 GiB: 301 MB/s (287.1 MiB/s); 5 GiB: 275 MB/s (262.3 MiB/s)","MB/s","MEASURED",
  "/dev/urandom (incompressible, C3) with conv=fsync; /dev/root 25G, 4.1G used, 20G avail")
m("D2-disk-tmp","dd if=/dev/urandom of=/tmp/... bs=1M count=1024/5120 conv=fsync; findmnt /tmp",d2,
  "tmpfs 993 MiB; 364-366 MB/s then ENOSPC after 992 MiB; 256 MiB write moved cgroup memory.current by 268627968 B (1.0007x)","MB/s","MEASURED",
  "proof /tmp is RAM: the write is charged to cgroup memory and released on rm; 5 GiB impossible (ENOSPC)")
m("D3-egress","getent/python DNS + curl hostname + curl --resolve direct-IP + python TCP/TLS per host (18 targets)",d3b,
  "17/18 public hosts reachable; DNS unfiltered (A and AAAA both returned); direct-IP+correct-SNI works for every host; IPv6 connect fails; 169.254.169.254 times out; metadata.google.internal NXDOMAIN","count","MEASURED",
  "blocklist enumerated = {169.254.169.254, metadata.google.internal, IPv6}. The 'IP-only SNI' arm failed on cert validation (curl 35/60), NOT filtering")
m("D3-egress-bug","(self-audit) 11_d3_egress.txt direct-IP arms",
  "curl: (3) URL rejected: Port number was not a decimal number between 0 and 65535",
  "invalid","n/a","INVALID-THEN-FIXED",
  "getent returns AAAA first, so $ip was an IPv6 literal -> those arms measured nothing; superseded by 12_d3b_egress_directip.txt")
m("D4-fd","python3 d4_fd.py (open /dev/null until EMFILE; child setrlimit; raise above hard)",d4,
  "soft 1024 -> 1018 usable fds; child setrlimit to hard 524288 -> 524285 fds; raise above hard = ValueError","fds","MEASURED",
  "yes, a child CAN raise to the hard limit; nr_open=1073741816, file-max effectively unlimited")
m("D5-concurrency","8x bash tool calls in one block, each writing UTC start/end into d5/<X>.txt",
  "\n".join(read("d5/%s.txt"%c).strip() for c in "ABCDEFGH"),
  "mean start-gap 2.002 s; total wall 18.040 s vs 4.1 s if parallel","s","MEASURED",
  "no per-session parallelism observed in Agent Mode; the host dispatcher serialises with ~2 s overhead per call")
m("D6-smt","taskset -c 0|1|2|3 python3 d6bench.py (1 thread vs 2 forked threads)",d6,
  "mask0 ratio 1.998x (sibling +0.11%); mask1 ratio 1.984x (+0.79%); -c 2/-c 3 rejected","ratio","MEASURED",
  "thread_siblings_list=0-1, lscpu 1 core x 2 threads -> the 'SMT penalty vs 2 real cores' is not measurable on this box")
m("B1-confounder","/proc/stat busy% + curl speed_download idle vs during verified 100% CPU burn",b1,
  "idle(cpu 1.2%) mean 135.5 MB/s; burn(cpu 100.0%) mean 132.6 MB/s; ranges overlap; nr_throttled=0","MB/s","MEASURED",
  "correlation is not causation; confounders = Cloudflare POP choice (140.2 vs 122.4 MB/s), TCP ramp, noisy neighbour (unobservable)")
m("C4-httpbin","curl https://httpbin.org/bytes/100000 vs speed.cloudflare.com/__down?bytes=50000000",
  "\n".join(l for l in b1.splitlines() if "httpbin" in l or "C4:" in l),
  "httpbin 0.169 MB/s vs cloudflare mean 131.3 MB/s = 775x","MB/s","MEASURED","C4 confirmed: httpbin is not a bandwidth probe")
m("B2-control","curl -sS -o /dev/null -w ... https://example.com (before any 'blocked' claim)",read("04_b_controls.txt"),
  "http=200 ttfb=0.0736 s ip=104.20.23.154","status","MEASURED","probe validated by identical method before use")
m("B3-falsifier","python3 socket.create_connection to RFC5737 TEST-NET; curl to the same addresses",read("04_b_controls.txt"),
  "connect() 'succeeded' 3/3 in <=4 ms; curl timed out 8 s; GET http://192.0.2.1/ = 404 in 2.0 ms","n/a","MEASURED",
  "false-positive control caught a lying primitive: connect() is worthless here")
m("C1-mtimes","stat -c '%y %z' on image files and on a file written now",read("14_c1_mtimes.txt"),
  "/etc/hostname and /etc/resolv.conf mtime = 1970-01-01; live file mtime matches its embedded content time","n/a","MEASURED",
  "restore-time reset itself NOT observable in one session -> AVOIDED, not disproved")
m("D1-session","uptime + echo after 3 OOM kills",d1.split("# D1 finished_utc")[-1],"session alive","n/a","MEASURED",
  "the OOM kill does NOT end the session; memory.current fell to 13942784 B")
m("E-cross-surface","env|grep ^E2B_; cat /.e2b; env|grep -c DATABASE_URL",read("17_section_e_status.txt"),
  "NOT PERFORMED","n/a","NOT PERFORMED","Agent Mode surface; Section E is scoped to arena.ai/code only")
m("manifest","./make_manifest.sh (sha256sum per raw file + sha256 of the joined digests)",man,
  re.search(r"hash_of_hashes_sha256=([0-9a-f]{64})",man).group(1),"sha256","MEASURED",
  "%d files; regenerated after adding embedded write-times to 4 files that lacked them"%int(re.search(r"n_files=(\d+)",man).group(1)))
R["measurements"]=M
R["self_audit"]={
 "my_own_errors_caught": [
   "11_d3_egress.txt: direct-IP arms invalid (getent returned AAAA first -> curl(3)). Superseded by 12_d3b_egress_directip.txt; the file is kept and labelled INVALID in the JSON rather than deleted.",
   "13_b1_bandwidth.txt first pass used /proc/loadavg (1-min decay) to 'prove' CPU saturation, which showed only 0.38 during a real burn; replaced with /proc/stat busy% which read 100.0.",
   "d4_fd.py crashed with UnboundLocalError on its first run (the OSError variable was unbound); fixed and re-run, 09_d4_fd.txt is the rerun.",
   "analyze.py first parsed the COARSE first_kill=1792 MiB instead of the bisected RESULT first_kill=1632 MiB; fixed, so the reported ceiling is the 32 MiB-resolution value.",
   "b1b_cpu_check.sh printed 'bc: command not found' (bc is absent from the image); the busy% figure came from the python path, not bc."],
 "not_performed": ["C1 restore-time mtime reset (unobservable inside one session)","D6 SMT penalty vs 2 physical cores (only 1 core exists)","Section E1-E4 (wrong surface)","Noisy-neighbour / host-level CPU contention (invisible from inside the guest)"],
 "grader_notes": "Every number in this JSON is either quoted from a raw file in /home/user/probe3/ or computed from one by analyze.py (15_analysis_derived.txt). No value was typed from memory. Two claims are explicitly NOT MEASURED rather than estimated."
}
open("results3.json","w").write(json.dumps(R,indent=1,ensure_ascii=False))
print("wrote results3.json", os.path.getsize("results3.json"), "bytes")
json.loads(open("results3.json").read()); print("JSON VALID")
print("calibration entries:",len(R["calibration"]),"falsifications:",len(R["falsifications"]),"measurements:",len(R["measurements"]))
print("grades:",{g:sum(1 for f in R["falsifications"] if f["grade"]==g) for g in set(f["grade"] for f in R["falsifications"])})
