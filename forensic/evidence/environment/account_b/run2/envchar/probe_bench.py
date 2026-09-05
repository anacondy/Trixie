#!/usr/bin/env python3
"""Network, CPU, disk, memory, and compile/install benches.
Writes numbered raw transcripts under ENVCHAR_OUT.
"""
from __future__ import annotations

import concurrent.futures
import hashlib
import os
import shutil
import socket
import ssl
import statistics
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

OUT = Path(os.environ.get("ENVCHAR_OUT", Path(__file__).resolve().parent / "raw"))
STAMP = os.environ.get("ENVCHAR_STAMP_UTC", time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()))
SKIP_DL = os.environ.get("ENVCHAR_SKIP_DOWNLOADS", "") in ("1", "true", "yes")
SKIP_MEM = os.environ.get("ENVCHAR_SKIP_MEMORY", "") in ("1", "true", "yes")
OUT.mkdir(parents=True, exist_ok=True)


def header(path: Path, title: str) -> None:
    path.write_text(
        "\n".join(
            [
                "# envchar raw transcript",
                f"# file: {path.name}",
                f"# title: {title}",
                f"# generated_utc: {STAMP}",
                f"# host: {socket.gethostname()}",
                f"# sandbox: {os.environ.get('E2B_SANDBOX_ID', 'unknown')}",
                f"# template: {os.environ.get('E2B_TEMPLATE_ID', 'unknown')}",
                f"# probe: {Path(__file__).resolve()}",
                "# NOTE: This file is a verbatim measurement transcript. Do not summarize.",
                "",
            ]
        )
        + "\n"
    )


def append(path: Path, text: str) -> None:
    with path.open("a") as f:
        f.write(text)
        if not text.endswith("\n"):
            f.write("\n")


def section(path: Path, name: str) -> None:
    append(
        path,
        "\n================================================================\n"
        f"=== {name}\n"
        f"=== UTC: {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}\n"
        "================================================================\n",
    )


def timed_cmd(path: Path, banner: str, argv: list[str], timeout: int = 120) -> int:
    section(path, banner)
    append(path, f"=== CMD: {' '.join(argv)}\n")
    t0 = time.perf_counter()
    try:
        p = subprocess.run(
            argv,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout,
            text=True,
        )
        append(path, p.stdout or "")
        rc = p.returncode
    except subprocess.TimeoutExpired as e:
        append(path, (e.stdout or "") if isinstance(e.stdout, str) else "")
        append(path, f"=== TIMEOUT after {timeout}s ===\n")
        rc = 124
    except Exception as e:
        append(path, f"=== EXC {type(e).__name__}: {e} ===\n")
        rc = 1
    wall = time.perf_counter() - t0
    append(path, f"=== EXIT: {rc}  WALL_S: {wall:.4f} ===\n")
    return rc


# ---------------------------------------------------------------------------
# 09 net matrix
# ---------------------------------------------------------------------------
f09 = OUT / "09_net_matrix.txt"
header(f09, "DNS resolution and TCP connect latency matrix")

section(f09, "DNS getaddrinfo 5 samples")
hosts = [
    "google.com",
    "www.google.com",
    "github.com",
    "pypi.org",
    "huggingface.co",
    "8.8.8.8",
    "cloudflare.com",
    "files.pythonhosted.org",
    "registry.npmjs.org",
    "cdn.jsdelivr.net",
    "www.wikipedia.org",
]
append(f09, f"{'host':28s} {'n':>3} {'min_ms':>8} {'mean_ms':>8} {'max_ms':>8} addrs/error\n")
for h in hosts:
    times = []
    addrs: set[str] = set()
    err = None
    for _ in range(5):
        t0 = time.perf_counter()
        try:
            info = socket.getaddrinfo(h, 443, proto=socket.IPPROTO_TCP)
            times.append((time.perf_counter() - t0) * 1000)
            addrs |= {x[4][0] for x in info}
        except Exception as e:
            times.append((time.perf_counter() - t0) * 1000)
            err = f"{type(e).__name__}: {e}"
    if times:
        append(
            f09,
            f"{h:28s} {len(times):3d} {min(times):8.1f} {statistics.mean(times):8.1f} {max(times):8.1f} "
            f"addrs={sorted(addrs)[:6]} err={err}\n",
        )

section(f09, "TCP connect 5 samples")
targets = [
    ("google.com", 443),
    ("www.google.com", 443),
    ("github.com", 443),
    ("github.com", 22),
    ("github.com", 80),
    ("pypi.org", 443),
    ("pypi.org", 80),
    ("huggingface.co", 443),
    ("8.8.8.8", 443),
    ("8.8.8.8", 53),
    ("1.1.1.1", 443),
    ("1.1.1.1", 80),
    ("1.1.1.1", 53),
    ("files.pythonhosted.org", 443),
    ("registry.npmjs.org", 443),
    ("cdn.jsdelivr.net", 443),
    ("smtp.gmail.com", 25),
    ("smtp.gmail.com", 587),
    ("example.com", 443),
]
append(
    f09,
    f"{'host':28s} {'port':>5} {'min_ms':>8} {'mean_ms':>8} {'max_ms':>8} err\n",
)
for host, port in targets:
    times = []
    err = None
    for _ in range(5):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(5)
        t0 = time.perf_counter()
        try:
            s.connect((host, port))
            times.append((time.perf_counter() - t0) * 1000)
        except Exception as e:
            times.append((time.perf_counter() - t0) * 1000)
            err = f"{type(e).__name__}: {e}"
        finally:
            s.close()
    append(
        f09,
        f"{host:28s} {port:5d} {min(times):8.1f} {statistics.mean(times):8.1f} {max(times):8.1f} {err}\n",
    )

section(f09, "IPv6 connect")
for host in ["google.com", "github.com", "pypi.org", "huggingface.co"]:
    try:
        infos = socket.getaddrinfo(host, 443, socket.AF_INET6, socket.SOCK_STREAM)
        addr = infos[0][4]
        s = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
        s.settimeout(3)
        t0 = time.perf_counter()
        try:
            s.connect(addr)
            append(f09, f"IPv6 {host} {addr} OK {(time.perf_counter()-t0)*1000:.1f}ms\n")
        except Exception as e:
            append(
                f09,
                f"IPv6 {host} {addr} FAIL {(time.perf_counter()-t0)*1000:.1f}ms {type(e).__name__}: {e}\n",
            )
        finally:
            s.close()
    except Exception as e:
        append(f09, f"IPv6 resolve {host} FAIL {type(e).__name__}: {e}\n")

section(f09, "UDP 53 DNS query")


def dns_query(server: str, timeout: float = 3.0):
    q = (
        b"\x12\x34\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00"
        + b"\x06google\x03com\x00\x00\x01\x00\x01"
    )
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(timeout)
    t0 = time.perf_counter()
    try:
        s.sendto(q, (server, 53))
        data, addr = s.recvfrom(512)
        return True, (time.perf_counter() - t0) * 1000, len(data), addr
    except Exception as e:
        return False, (time.perf_counter() - t0) * 1000, str(e), None
    finally:
        s.close()


for srv in ["8.8.8.8", "1.1.1.1"]:
    ok, dt, extra, addr = dns_query(srv)
    append(f09, f"UDP/53 {srv}: ok={ok} {dt:.1f}ms extra={extra} from={addr}\n")

section(f09, "UDP 123 NTP")
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.settimeout(3)
t0 = time.perf_counter()
try:
    s.sendto(b"\x1b" + b"\0" * 47, ("time.google.com", 123))
    data, addr = s.recvfrom(512)
    append(f09, f"NTP OK {(time.perf_counter()-t0)*1000:.1f}ms {len(data)}B from {addr}\n")
except Exception as e:
    append(f09, f"NTP FAIL {(time.perf_counter()-t0)*1000:.1f}ms {type(e).__name__}: {e}\n")
finally:
    s.close()

section(f09, "UDP 443 probe")
for host in ["1.1.1.1", "8.8.8.8"]:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(3)
    t0 = time.perf_counter()
    try:
        s.sendto(b"hello", (host, 443))
        data, addr = s.recvfrom(512)
        append(f09, f"UDP/443 {host} OK {(time.perf_counter()-t0)*1000:.1f}ms {len(data)}B {addr}\n")
    except Exception as e:
        append(f09, f"UDP/443 {host} FAIL {(time.perf_counter()-t0)*1000:.1f}ms {type(e).__name__}: {e}\n")
    finally:
        s.close()

print("[probe] 09_net_matrix.txt", flush=True)

# ---------------------------------------------------------------------------
# 10 throughput
# ---------------------------------------------------------------------------
f10 = OUT / "10_net_throughput.txt"
header(f10, "HTTPS throughput (curl -w and python urllib)")

if SKIP_DL:
    append(f10, "SKIPPED because ENVCHAR_SKIP_DOWNLOADS=1\n")
else:
    downloads = [
        ("github_jq_linux64", "https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64"),
        ("pypi_simple_pip", "https://pypi.org/simple/pip/"),
        ("cloudflare_1MB", "https://speed.cloudflare.com/__down?bytes=1000000"),
        ("cloudflare_10MB", "https://speed.cloudflare.com/__down?bytes=10000000"),
        ("cloudflare_50MB", "https://speed.cloudflare.com/__down?bytes=50000000"),
        ("nodejs_headers", "https://nodejs.org/dist/v20.20.2/node-v20.20.2-headers.tar.gz"),
        ("hf_bert_config", "https://huggingface.co/bert-base-uncased/raw/main/config.json"),
        ("hf_bert_tokenizer", "https://huggingface.co/bert-base-uncased/resolve/main/tokenizer.json"),
        ("google_home", "https://www.google.com/"),
        ("github_home", "https://github.com/"),
        ("hf_home", "https://huggingface.co/"),
    ]
    writeout = (
        "http_code=%{http_code} size=%{size_download} speed_Bps=%{speed_download} "
        "namelookup=%{time_namelookup} connect=%{time_connect} tls=%{time_appconnect} "
        "ttfb=%{time_starttransfer} total=%{time_total} ip=%{remote_ip} "
        "num_redirects=%{num_redirects} ctype=%{content_type} err=%{errormsg}\\n"
    )
    for label, url in downloads:
        outbin = f"/tmp/envchar_dl_{label}.bin"
        timed_cmd(
            f10,
            f"curl {label}",
            [
                "curl",
                "-L",
                "--http1.1",
                "-o",
                outbin,
                "-w",
                writeout,
                "-A",
                "envchar-probe/1.0",
                "--max-time",
                "120",
                url,
            ],
            timeout=130,
        )
        if os.path.exists(outbin):
            st = os.stat(outbin)
            h = hashlib.sha256()
            with open(outbin, "rb") as fh:
                for chunk in iter(lambda: fh.read(1024 * 1024), b""):
                    h.update(chunk)
            append(f10, f"saved_bytes={st.st_size} sha256={h.hexdigest()}\n")
            os.remove(outbin)

    timed_cmd(
        f10,
        "curl http2 pypi.org",
        [
            "curl",
            "-s",
            "-o",
            "/dev/null",
            "-w",
            "http=%{http_version} ttfb=%{time_starttransfer} total=%{time_total} size=%{size_download}\\n",
            "--http2",
            "https://pypi.org/",
        ],
    )
    timed_cmd(
        f10,
        "curl http1.1 pypi.org",
        [
            "curl",
            "-s",
            "-o",
            "/dev/null",
            "-w",
            "http=%{http_version} ttfb=%{time_starttransfer} total=%{time_total} size=%{size_download}\\n",
            "--http1.1",
            "https://pypi.org/",
        ],
    )
    timed_cmd(
        f10,
        "wget jq",
        [
            "wget",
            "-q",
            "-O",
            "/tmp/envchar_wget.bin",
            "https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64",
        ],
    )
    if os.path.exists("/tmp/envchar_wget.bin"):
        append(f10, f"wget_bytes={os.path.getsize('/tmp/envchar_wget.bin')}\n")
        os.remove("/tmp/envchar_wget.bin")

print("[probe] 10_net_throughput.txt", flush=True)

# ---------------------------------------------------------------------------
# 11 ports
# ---------------------------------------------------------------------------
f11 = OUT / "11_net_ports.txt"
header(f11, "Outbound TCP port probe")
section(f11, "TCP connect one-shot")
tests = [
    ("1.1.1.1", 53, "dns-tcp"),
    ("1.1.1.1", 80, "http"),
    ("1.1.1.1", 443, "https"),
    ("1.1.1.1", 853, "dot"),
    ("8.8.8.8", 53, "dns-tcp"),
    ("8.8.8.8", 443, "https"),
    ("github.com", 22, "ssh"),
    ("github.com", 80, "http"),
    ("github.com", 443, "https"),
    ("github.com", 9418, "git-daemon"),
    ("smtp.gmail.com", 25, "smtp"),
    ("smtp.gmail.com", 465, "smtps"),
    ("smtp.gmail.com", 587, "smtp-sub"),
    ("pypi.org", 80, "http"),
    ("pypi.org", 443, "https"),
    ("huggingface.co", 443, "https"),
    ("scanme.nmap.org", 22, "ssh-scanme"),
    ("scanme.nmap.org", 80, "http-scanme"),
    ("example.com", 443, "https-ex"),
]
append(f11, f"{'result':8s} {'label':16s} {'host':22s} {'port':>5} {'ms':>8} extra\n")
for host, port, label in tests:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(4)
    t0 = time.perf_counter()
    try:
        s.connect((host, port))
        dt = (time.perf_counter() - t0) * 1000
        append(f11, f"{'OPEN':8s} {label:16s} {host:22s} {port:5d} {dt:8.1f}\n")
    except socket.timeout:
        dt = (time.perf_counter() - t0) * 1000
        append(f11, f"{'TIMEOUT':8s} {label:16s} {host:22s} {port:5d} {dt:8.1f}\n")
    except Exception as e:
        dt = (time.perf_counter() - t0) * 1000
        append(
            f11,
            f"{'FAIL':8s} {label:16s} {host:22s} {port:5d} {dt:8.1f} {type(e).__name__}: {e}\n",
        )
    finally:
        s.close()

section(f11, "TLS certificate subjects")
for host in ["www.google.com", "github.com", "pypi.org", "huggingface.co"]:
    try:
        p = subprocess.run(
            ["bash", "-lc", f"echo | timeout 8 openssl s_client -connect {host}:443 -servername {host} 2>/dev/null | openssl x509 -noout -subject -issuer -dates"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=12,
        )
        append(f11, f"--- {host} ---\n{p.stdout}\n")
    except Exception as e:
        append(f11, f"--- {host} EXC {e}\n")

print("[probe] 11_net_ports.txt", flush=True)

# ---------------------------------------------------------------------------
# 12 cpu
# ---------------------------------------------------------------------------
f12 = OUT / "12_cpu_bench.txt"
header(f12, "CPU microbenchmarks")
section(f12, "python benches (3 repeats, perf_counter)")


def bench(name, fn, repeat=3):
    times = []
    result = None
    for _ in range(repeat):
        t0 = time.perf_counter()
        result = fn()
        times.append(time.perf_counter() - t0)
    line = (
        f"{name:42s} n={repeat} min_ms={min(times)*1000:8.2f} "
        f"mean_ms={sum(times)/len(times)*1000:8.2f} max_ms={max(times)*1000:8.2f} result={result!r}"
    )
    append(f12, line + "\n")
    return times


bench("sum(range(10**7))", lambda: sum(range(10**7)))


def heavier():
    s = 0
    for i in range(2_000_000):
        s += i * i ^ (i << 1)
    return s


bench("heavier python loop 2e6", heavier)

import math


def mathloop():
    x = 0.0
    for i in range(1_000_000):
        x += math.sin(i) * math.sqrt(i + 1)
    return x


bench("sin/sqrt 1e6", mathloop)

try:
    import numpy as np

    def npsum():
        a = np.arange(10_000_000, dtype=np.int64)
        return int(a.sum())

    bench("numpy arange(1e7).sum()", npsum)

    def npdot():
        rng = np.random.default_rng(0)
        a = rng.random((800, 800), dtype=np.float64)
        b = rng.random((800, 800), dtype=np.float64)
        c = a @ b
        return float(c[0, 0])

    bench("numpy 800x800 matmul float64", npdot)

    def npsort():
        rng = np.random.default_rng(1)
        a = rng.random(5_000_000, dtype=np.float64)
        a.sort()
        return float(a[0])

    bench("numpy sort 5e6 float64", npsort)
except Exception as e:
    append(f12, f"numpy benches failed: {type(e).__name__}: {e}\n")


def sha():
    h = hashlib.sha256()
    b = b"x" * 1024 * 1024
    for _ in range(50):
        h.update(b)
    return h.hexdigest()[:16]


bench("sha256 50MB in-memory", sha)
append(f12, f"python {sys.version}\n")
append(f12, f"os.cpu_count={os.cpu_count()}\n")

section(f12, "compile and run C")
c_src = Path("/tmp/envchar_hello.c")
c_src.write_text(
    """#include <stdio.h>
#include <math.h>
int main(void) {
    double s = 0;
    for (long i = 0; i < 10000000L; i++) s += sin((double)i);
    printf("ok %.6f\\n", s);
    return 0;
}
"""
)
timed_cmd(f12, "gcc -O2", ["gcc", "-O2", "-o", "/tmp/envchar_hello", str(c_src), "-lm"])
timed_cmd(f12, "run hello", ["/tmp/envchar_hello"])

cpp_src = Path("/tmp/envchar_hello.cpp")
cpp_src.write_text(
    """#include <iostream>
#include <vector>
#include <numeric>
int main() {
    std::vector<int> v(1000000);
    std::iota(v.begin(), v.end(), 1);
    long long s = 0; for (int x: v) s += x;
    std::cout << "ok " << s << "\\n";
}
"""
)
timed_cmd(f12, "g++ -O2", ["g++", "-O2", "-std=c++17", "-o", "/tmp/envchar_hello_cpp", str(cpp_src)])
timed_cmd(f12, "run hello_cpp", ["/tmp/envchar_hello_cpp"])

print("[probe] 12_cpu_bench.txt", flush=True)

# ---------------------------------------------------------------------------
# 13 disk
# ---------------------------------------------------------------------------
f13 = OUT / "13_disk_bench.txt"
header(f13, "Disk sequential write/read 80 MiB")
section(f13, "80 MiB random payload write+fsync / drop_caches / read")

size = 80 * 1024 * 1024
block = 1024 * 1024
payload = os.urandom(block)


def bench_path(path: str) -> None:
    append(f13, f"--- {path} ---\n")
    t0 = time.perf_counter()
    with open(path, "wb", buffering=block) as fh:
        written = 0
        while written < size:
            fh.write(payload)
            written += block
        fh.flush()
        os.fsync(fh.fileno())
    wsec = time.perf_counter() - t0
    actual = os.path.getsize(path)
    append(
        f13,
        f"write+fsync bytes={actual} sec={wsec:.4f} MiB_s={actual/wsec/1024/1024:.2f}\n",
    )
    subprocess.run(["sync"], check=False)
    subprocess.run(
        ["sudo", "sh", "-c", "echo 3 > /proc/sys/vm/drop_caches"],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    h = hashlib.sha256()
    t0 = time.perf_counter()
    n = 0
    with open(path, "rb", buffering=block) as fh:
        while True:
            b = fh.read(block)
            if not b:
                break
            n += len(b)
            h.update(b)
    rsec = time.perf_counter() - t0
    append(
        f13,
        f"uncached_read bytes={n} sec={rsec:.4f} MiB_s={n/rsec/1024/1024:.2f} sha256={h.hexdigest()}\n",
    )
    t0 = time.perf_counter()
    n = 0
    with open(path, "rb", buffering=block) as fh:
        while True:
            b = fh.read(block)
            if not b:
                break
            n += len(b)
    rsec = time.perf_counter() - t0
    append(
        f13,
        f"cached_reread bytes={n} sec={rsec:.4f} MiB_s={n/rsec/1024/1024:.2f}\n",
    )
    os.remove(path)
    append(f13, "deleted OK\n")


for p in [
    "/home/user/_envchar_80mb.bin",
    "/tmp/_envchar_80mb.bin",
    "/var/tmp/_envchar_80mb.bin",
]:
    try:
        bench_path(p)
    except Exception as e:
        append(f13, f"FAIL {p} {type(e).__name__}: {e}\n")

print("[probe] 13_disk_bench.txt", flush=True)

# ---------------------------------------------------------------------------
# 14 installs
# ---------------------------------------------------------------------------
f14 = OUT / "14_installs.txt"
header(f14, "Package install timings (apt/pip/npm/git)")
timed_cmd(f14, "apt-get update", ["sudo", "apt-get", "update", "-qq"], timeout=90)
# tree may already be installed; still record
timed_cmd(
    f14,
    "apt-get install tree",
    ["sudo", "env", "DEBIAN_FRONTEND=noninteractive", "apt-get", "install", "-y", "tree"],
    timeout=90,
)
timed_cmd(f14, "tree --version", ["tree", "--version"])
timed_cmd(
    f14,
    "pip install tabulate==0.9.0",
    [sys.executable, "-m", "pip", "install", "--disable-pip-version-check", "tabulate==0.9.0"],
    timeout=90,
)
timed_cmd(
    f14,
    "python import tabulate",
    [sys.executable, "-c", "import tabulate; print(tabulate.__version__)"],
)
npm_dir = Path("/tmp/envchar_npm")
if npm_dir.exists():
    shutil.rmtree(npm_dir, ignore_errors=True)
npm_dir.mkdir()
(npm_dir / "package.json").write_text('{"name":"t","private":true}\n')
timed_cmd(
    f14,
    "npm install left-pad (in /tmp/envchar_npm)",
    ["bash", "-lc", "cd /tmp/envchar_npm && npm install left-pad --no-fund --no-audit"],
    timeout=90,
)
git_dir = "/tmp/envchar_jq_src"
shutil.rmtree(git_dir, ignore_errors=True)
timed_cmd(
    f14,
    "git clone --depth 1 jqlang/jq",
    ["git", "clone", "--depth", "1", "https://github.com/jqlang/jq.git", git_dir],
    timeout=90,
)
timed_cmd(f14, "du jq src", ["du", "-sh", git_dir])
shutil.rmtree(git_dir, ignore_errors=True)
shutil.rmtree(npm_dir, ignore_errors=True)

print("[probe] 14_installs.txt", flush=True)

# ---------------------------------------------------------------------------
# 15 memory
# ---------------------------------------------------------------------------
f15 = OUT / "15_memory.txt"
header(f15, "Memory pressure allocation")
section(f15, "50 MiB bytearray chunks until MemAvailable < 80 MiB")
if SKIP_MEM:
    append(f15, "SKIPPED because ENVCHAR_SKIP_MEMORY=1\n")
else:
    def meminfo_line(key: str) -> int:
        for line in Path("/proc/meminfo").read_text().splitlines():
            if line.startswith(key):
                return int(line.split()[1])
        return -1

    append(f15, f"MemTotal_kB={meminfo_line('MemTotal:')}\n")
    append(f15, f"MemAvailable_kB_before={meminfo_line('MemAvailable:')}\n")
    append(f15, f"MemFree_kB_before={meminfo_line('MemFree:')}\n")
    chunks = []
    try:
        for i in range(40):
            chunks.append(bytearray(50 * 1024 * 1024))
            avail = meminfo_line("MemAvailable:")
            free = meminfo_line("MemFree:")
            rss = int(
                [
                    ln.split()[1]
                    for ln in Path("/proc/self/status").read_text().splitlines()
                    if ln.startswith("VmRSS:")
                ][0]
            )
            append(
                f15,
                f"chunk={i+1:02d} approx_MB={(i+1)*50} rss_kB={rss} MemFree_kB={free} MemAvailable_kB={avail}\n",
            )
            if avail < 80 * 1024:
                append(f15, "stopping: MemAvailable < 80MB\n")
                break
    except MemoryError as e:
        append(f15, f"MemoryError after {len(chunks)} chunks: {e}\n")
    except Exception as e:
        append(f15, f"{type(e).__name__}: {e}\n")
    del chunks
    import gc

    gc.collect()
    append(f15, f"MemAvailable_kB_after={meminfo_line('MemAvailable:')}\n")
    append(f15, f"MemFree_kB_after={meminfo_line('MemFree:')}\n")
    try:
        peak = Path("/sys/fs/cgroup/user/memory.peak").read_text().strip()
        events = Path("/sys/fs/cgroup/user/memory.events").read_text()
        append(f15, f"cgroup_user_memory.peak={peak}\n")
        append(f15, f"cgroup_user_memory.events=\n{events}")
    except Exception as e:
        append(f15, f"cgroup read fail {e}\n")

print("[probe] 15_memory.txt", flush=True)
